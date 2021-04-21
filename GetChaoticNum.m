function [outputArg1] = GetChaoticNum(Initial_Value,row,column)
Num = addChaos(Initial_Value,row,column);
r=randi(row);
while r == 1
         r=randi(row);
end
outputArg1=Num(1,r);
end

