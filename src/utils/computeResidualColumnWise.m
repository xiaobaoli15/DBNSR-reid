function residual = computeResidualColumnWise(eachfeaturesTest,idPersons,...
   Dnorm,Alphaband)
residual = repmat( eachfeaturesTest,1,length(idPersons) ) ...
   - (Dnorm*Alphaband);
return