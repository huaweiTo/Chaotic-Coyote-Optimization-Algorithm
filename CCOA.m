function [GlobalParams,GlobalMin,costs] =CCOA
%% ------------------------------------------------------------------------
% coded by huawei Tong, 2021-04-21
% Our paper : 
% Tong, H., Zhu, Y., Pierezan, J. et al. Chaotic Coyote Optimization Algorithm. J Ambient Intell Human Comput (2021). https://doi.org/10.1007/s12652-021-03234-5


%% Optimization problem variables
global lu nfevalMAX D FOBJ;
VarMin      = lu(1,:);
VarMax      = lu(2,:);
global Np Nc ;
n_packs = Np ; n_coy = Nc;
global Initial_Value_1 Initial_Value_2 ;

if n_coy < 3, error('At least 3 coyotes per pack!'); end
% Probability of leaving a pack
p_leave = 0.005*n_coy^2;
Ps = 1/D; 

%% Packs initialization
pop_total = n_packs*n_coy ; 
costs = zeros(pop_total,1);
all_total = pop_total*D; 
chaotic_seq4 = addChaos(Initial_Value_1,all_total+1,1);
chaotic_seq4 = chaotic_seq4(2:all_total+1);
chaotic_seq4= reshape(chaotic_seq4,pop_total,D);

coyotes     = repmat(VarMin,pop_total,1) +chaotic_seq4.*(repmat(VarMax,pop_total,1) - repmat(VarMin,pop_total,1)); 
ages = zeros(pop_total,1);
packs = reshape(randperm(pop_total),n_packs,[]);

coypack = repmat(n_coy,n_packs,1);

%% Evaluate coyotes adaptation
for c=1:pop_total 
    costs(c,1) = FOBJ(coyotes(c,:));
end
nfeval = pop_total;
%% Output variables
[GlobalMin,ibest] = min(costs);
GlobalParams  = coyotes(ibest,:);

%% Main loop
NumLoop = 0;
while nfeval < nfevalMAX
    % Stopping criteria 
    %% Update the NumLoop
    NumLoop = NumLoop + 1;
    %% Execute the operations inside each pack
    for p=1:n_packs
        chaotic_seq2=zeros(2,n_coy+1);
        %Produce chaos seqences
        chaotic_seq2(1,:)= addChaos(Initial_Value_1,n_coy+1,1);
        chaotic_seq2(2,:)=addChaos(Initial_Value_2,n_coy+1,1);
        % Get the coyotes that belong to each pack
        coyotes_aux = coyotes(packs(p,:),:);
        costs_aux = costs(packs(p,:),:);
        ages_aux = ages(packs(p,:),1);
        n_coy_aux = coypack(p,1);
        
        % Detect alphas according to the costs
        [costs_aux,inds] = sort(costs_aux,'ascend');
        coyotes_aux = coyotes_aux(inds,:);
        ages_aux = ages_aux(inds,:);
        c_alpha = coyotes_aux(1,:); 
        
        % Compute the social tendency of the pack 
        tendency = median(coyotes_aux,1);
       
        % Update coyotes' social condition
        new_coyotes      = zeros(n_coy_aux,D);
        for c=1:n_coy_aux
            rc1 = randi(n_coy_aux);
            rc2 = randi(n_coy_aux);
            while rc2 == rc1
                rc2 = randi(n_coy_aux);
            end
            
            % Try to update the social condition
            % according to the alpha and the pack tendency
            new_c = coyotes_aux(c,:) + ...
                chaotic_seq2(1,c+1)*(c_alpha - coyotes_aux(rc1,:))+ ...
                chaotic_seq2(2,c+1)*(tendency  - coyotes_aux(rc2,:));
            % Keep the coyotes in the search space (optimization problem constraint)
            new_coyotes(c,:) = min(max(new_c,VarMin),VarMax);
            % Evaluate the new social condition 
            new_cost = FOBJ(new_coyotes(c,:));
            
            nfeval = nfeval+1;
            
            % Adaptation
            if new_cost < costs_aux(c,1)
                costs_aux(c,1) = new_cost;
                coyotes_aux(c,:)    = new_coyotes(c,:);
            end
        end
        %% Birth of a new coyote from random parents 
        parents         = randperm(n_coy_aux,2);
        prob1           = (1-Ps)/2; 
        prob2           = prob1;
        pdr             = randperm(D); 
        p1              = zeros(1,D);
        p2              = zeros(1,D);
        p1(pdr(1))      = 1; % Guarantee 1 charac. per individual
        p2(pdr(2))      = 1; % Guarantee 1 charac. per individual
        r               = rand(1,D-2);
        p1(pdr(3:end))  = r < prob1;
        p2(pdr(3:end))  = r > 1-prob2;
        % Eventual noise
        n  = ~(p1|p2);
        
        % Generate the pup considering intrinsic and extrinsic influence
        chaoticNum = GetChaoticNum(Initial_Value_1,n_coy,1);
        pup =   p1.*coyotes_aux(parents(1),:) + ...
                    p2.*coyotes_aux(parents(2),:) + ...
                    n.*(VarMin + chaoticNum.*(VarMax-VarMin));
        
        
        % Verify if the pup will survive
        pup_cost    = FOBJ(pup);
        nfeval      = nfeval + 1;
        worst       = find(pup_cost < costs_aux == 1);
        if ~isempty(worst)
            [~,older]      = sort(ages_aux(worst),'descend');
            which                   = worst(older);
            coyotes_aux(which(1),:) = pup;
            costs_aux(which(1),1)   = pup_cost;
            ages_aux(which(1),1)    = 0;
        end
        
        %% Update the pack information
        coyotes(packs(p,:),:) = coyotes_aux;
        costs(packs(p,:),:)   = costs_aux;
        ages(packs(p,:),1)    = ages_aux;
    end
    %% A coyote can leave a pack and enter in another pack
    if n_packs > 1
        chaoticNum2 = GetChaoticNum(Initial_Value_1,n_coy,1);
        if chaoticNum2 < p_leave
            rp                  = randperm(n_packs,2);
            rc                  = randi(n_coy,1,2);
            aux                 = packs(rp(1),rc(1));
            packs(rp(1),rc(1))  = packs(rp(2),rc(2));
            packs(rp(2),rc(2))  = aux;
        end
    end
    
    %% Update coyotes ages
    ages = ages + 1;
    %% Output variables (best alpha coyote among all alphas)
    [GlobalMin,ibest]   = min(costs);
    GlobalParams  = coyotes(ibest,:);
end

end
