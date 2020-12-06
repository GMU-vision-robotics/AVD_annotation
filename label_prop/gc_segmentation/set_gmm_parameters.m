% this function sets the gmm model parameters
% INPUT

% means	    	means of the GMM. 3xk matrix
% covariances   diagonal covariance matrix 3xk matrix
% priors        prior of each GMM kx1 vector
% k  		number of mixtures

% OUTPUT  
% model     	the GMM model fitted. model.mu contains the means of the
%           	component Gaussian. model.Sigma contains the covariance matrices, and
%           	model.weights contains the priors
  
% Md. Alimoor Reza, November 2013

function [ model ] = set_gmm_parameters( means, covariances, priors, k )
model.mu = zeros(3,k);
model.Sigma = zeros(3,3,k);
model.weight = zeros(1,k);
for i=1:k
    model.mu(:,i) = means(:,i);
    tmp = zeros(3,3);
    tmp(1,1) = covariances(1,i); tmp(2,2) = covariances(2,i); tmp(3,3) = covariances(3,i);
    model.Sigma(:,:,i) = tmp;
    model.weight(i) = priors(i);
end


end

