MU1 = [3];
SIGMA1 = [1];
MU2 = [10];
SIGMA2 = [2];
X = [mvnrnd(MU1,SIGMA1,100);
mvnrnd(MU2,SIGMA2,100)];
% scatter(X(:,1),X(:,2),10,'.')
hist(X);
% title('histogram');
% pause;
% close;
options = statset('Display','final');
obj = gmdistribution.fit(X,2,'Options',options);
ComponentMeans = obj.mu
ComponentCovariances = obj.Sigma