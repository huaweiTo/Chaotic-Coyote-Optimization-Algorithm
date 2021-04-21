function F=addChaos(Initial_Value,Max_iter,v)
G = zeros(1,Max_iter);
x(1)=Initial_Value;
%Chebyshev map
for i=1:Max_iter
    x(i+1)=cos(i*acos(x(i)));
    %                 G(i)=((x(i)+1)*100)/2;
end
%normalize it from [-1 1] to [0 1]
a=-1; b=1; c=0; d=1;
x=((x-a)*(d-c))/(b-a);
G=x*v;
G=G(1:Max_iter);

F=G; 
end