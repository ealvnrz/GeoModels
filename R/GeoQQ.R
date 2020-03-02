


GeoQQ<-function(fit)
{

if(class(fit)!="GeoFit") stop("A GeoFit object is needed as input\n")
model=fit$model        #type of model

xlab="Theoretical Quantiles"
ylab="Sample Quantiles"
##########################################################
##########################################################
if(!fit$bivariate){

if(is.list(fit$coordx_dyn)) dd=unlist(fit$data)
else dd=c(t(fit$data))

N= length(dd)
probabilities= (1:N)/(N+1)

#######################################
if(model %in% c("Gaussian")) qqnorm(dd,main="Gaussian qq-plot")
#######################################
if(model %in% c("SkewGaussian"))
{
   omega=sqrt((fit$param["skew"]^2 + fit$param["sill"])/fit$param["sill"])
   alpha=fit$param["skew"]/fit$param["sill"]^0.5
   skgauss.quantiles=sn::qsn(probabilities,xi=0,
                       omega= as.numeric(omega),alpha= as.numeric(alpha),
                       solver= "RFB")
   plot(sort(skgauss.quantiles),sort(c(dd)),main="Skew Gaussian qq-plot",xlab=xlab,ylab=ylab)
}
#######################################
if(model%in%c("StudentT","Gaussian_misp_StudentT")) 
{
      limma::qqt(dd,df=as.numeric(round(1/fit$param["df"])),main="t qq-plot",xlab=xlab,ylab=ylab)
}
#######################################
if(model %in% c("Weibull"))
{
   shape=fit$param["shape"]
   weibull.quantiles=qweibull(probabilities,shape=shape,scale=1/(gamma(1+1/shape )))
   plot(sort(weibull.quantiles),sort(c(dd)), main ="Weibull qq-plot ",xlab=xlab,ylab=ylab)
}
#######################################
if(model %in% c("Gamma"))
{
   shape=fit$param["shape"]
   gamma.quantiles=qgamma(probabilities,shape=shape/2,scale=shape/2)
   plot(sort(gamma.quantiles),sort(c(dd)), main ="Gamma qq-plot ",xlab=xlab,ylab=ylab)
}
#######################################
abline(0,1)
 }
##########################################################
##########################################################

if(fit$bivariate){
par(mfrow=c(1,2))

if(is.list(fit$coordx_dyn)){ dd1=fit$data[[1]];dd2=fit$data[[2]]}
else  {dd1=fit$data[1,];dd2=fit$data[2,];}
N1= length(dd1);N2= length(dd2)
probabilities1= (1:N1)/(N1+1); probabilities2= (1:N2)/(N2+1); 


##########################################################

if(model %in% c("Gaussian")) { qqnorm(dd1,main="First Gaussian qq-plot");abline(0,1)
                               qqnorm(dd2,main="Second Gaussian qq-plot");abline(0,1)}

##########################################################

if(model %in% c("SkewGaussian"))
{
   omega1=sqrt((fit$param["skew_1"]^2 + fit$param["sill_1"])/fit$param["sill_1"])
   alpha1=fit$param["skew_1"]/fit$param["sill_1"]^0.5
   skgauss.quantiles1=sn::qsn(probabilities1,xi=0,
                       omega= as.numeric(omega1),alpha= as.numeric(alpha1),
                       solver= "RFB")
   plot(sort(skgauss.quantiles1),sort(c(dd1)),main="First Skew Gaussian qq-plot",xlab=xlab,ylab=ylab)
   abline(0,1)

   omega2=sqrt((fit$param["skew_2"]^2 + fit$param["sill_2"])/fit$param["sill_2"])
   alpha2=fit$param["skew_2"]/fit$param["sill_2"]^0.5
   skgauss.quantiles2=sn::qsn(probabilities2,xi=0,
                       omega= as.numeric(omega2),alpha= as.numeric(alpha2),
                       solver= "RFB")
   plot(sort(skgauss.quantiles2),sort(c(dd2)),main="Second Skew Gaussian qq-plot",xlab=xlab,ylab=ylab)
   abline(0,1)
}

##########################################################



par(mfrow=c(1,1))
  }
}