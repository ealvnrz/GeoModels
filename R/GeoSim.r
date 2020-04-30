####################################################
### Authors: Moreno Bevilacqua, Víctor Morales Oñate.
### Email: moreno.bevilacqua@uv.cl, victor.morales@uv.cl
### Universidad de Valparaiso, Departamento de Estad?stica
### File name: Simulation.r
### Description:
### This file contains a set of procedures
### for the simulation of Gaussian random fields and
### related functions.
### Last change: 28/04/2020
####################################################
 

# Simulate spatial and spatio-temporal random felds:
GeoSim <- function(coordx, coordy=NULL, coordt=NULL, coordx_dyn=NULL,corrmodel, distance="Eucl",GPU=NULL, grid=FALSE, 
     local=c(1,1),method="cholesky",model='Gaussian', n=1, param, radius=6371, sparse=FALSE,X=NULL)
{
####################################################################
############ internal function #####################################
####################################################################
ddim<-function(coordx,coordy,coordt)  
{
dimt=1
if(is.null(coordy))  dims=dim(coordx)[1]
else                 dims=length(coordx)*length(coordy)
if(!is.null(coordt)) dimt=length(coordt)
return(dims*dimt)
} 
forGaussparam<-function(model,param,bivariate)
{
   if(model %in% c("SkewGaussian","SkewGauss","TwoPieceGaussian","TwoPieceGauss"))  {
     if(!bivariate) param[which(names(param) %in% c("skew"))] <- NULL
     if(bivariate)  param[which(names(param) %in% c("skew_1","skew_2"))] <- NULL
                  
   }

     if(model %in% c("SkewStudentT","TwoPieceStudentT")){
     if(!bivariate) param[which(names(param) %in% c("df","skew"))] <- NULL
     if(bivariate)  param[which(names(param) %in% c("df_1","df_2","skew_1","skew_2"))] <- NULL
   }
       if(model %in% c("TwoPieceBimodal")){
     if(!bivariate) param[which(names(param) %in% c("df","shape","skew"))] <- NULL
     if(bivariate)  param[which(names(param) %in% c("df_1","df_2","shape_1","shape_2","skew_1","skew_2"))] <- NULL
   }

    if(model %in% c("Tukeygh","SinhAsinh","TwoPieceTukeyh")){
     if(!bivariate) param[which(names(param) %in% c("skew","tail"))] <- NULL
     if(bivariate)  param[which(names(param) %in% c("skew_1","skew_2","tail_1","tail_2"))] <- NULL
   }
      if(model %in% c("Tukeyh"))  {
     if(!bivariate) param[which(names(param) %in% c("tail"))] <- NULL
     if(bivariate)  param[which(names(param) %in% c("tail_1","tail_2"))] <- NULL
   } 

      if(model %in% c("Tukeyh2"))  {
     if(!bivariate) param[which(names(param) %in% c("tail1","tail2"))] <- NULL
     #if(bivariate)  param[which(names(param) %in% c("tail_1","tail_2"))] <- NULL
   } 


    if(model %in% c("Gamma","LogLogistic","Weibull"))  {
     if(!bivariate) param[which(names(param) %in% c("shape"))] <- NULL
     if(bivariate)  param[which(names(param) %in% c("shape_1","shape_2"))] <- NULL
   }  
     if(model %in% c("Beta",'Kumaraswamy'))  {
     if(!bivariate) param[which(names(param) %in% c("shape1","shape2"))] <- NULL
      #    if(!bivariate) param[which(names(param) %in% c("shape1","shape2"))] <- NULL
     if(!bivariate) param[which(names(param) %in% c("shape1","shape2","min","max"))] <- NULL
     if(bivariate)  {}
   }  
     if(model %in% c("StudentT"))  {
     if(!bivariate) param[which(names(param) %in% c("df"))] <- NULL
     if(bivariate)  param[which(names(param) %in% c("df_1","df_2"))] <- NULL
   }  
     
 return(param)   
}
##############################################################################
########### for Gaussian and non Gaussian RF obtained using Gaussian RF ######
##############################################################################
     RFfct1<- function(ccov,dime,nuisance,param,simd,X,ns)
    {
        numcoord=ccov$numcoord; numtime=ccov$numtime;grid=ccov$grid;
        spacetime=ccov$spacetime;bivariate=ccov$bivariate
        
        if(!bivariate) {if(is.null(dim(X))) {X=as.matrix(rep(1,numcoord*numtime))}}  ## in the case of no covariates
        if( bivariate) {if(is.null(dim(X))) {X=as.matrix(rep(1,ns[1]+ns[2]))}}
    

        if(!bivariate) {
                               sel=substr(names(nuisance),1,4)=="mean"; 
                               num_betas=sum(sel);mm=NULL
                               if(num_betas==1) mm=nuisance$mean
                               if(num_betas>1)  mm=c(mm,as.numeric((nuisance[sel])))
                               sim <- X%*%mm+simd 
                              }
                if(bivariate)  { 
                  sel1=substr(names(nuisance),1,6)=="mean_1";
                  sel2=substr(names(nuisance),1,6)=="mean_2";
                  num_betas1=sum(sel1);mm1=NULL;
                  num_betas2=sum(sel2);mm2=NULL;

                   if(num_betas1==1) mm1=nuisance$mean_1
                   if(num_betas1>1)  mm1=c(mm1,as.numeric((nuisance[sel1])))
                   if(num_betas2==1) mm2=nuisance$mean_2
                   if(num_betas2>1)  mm2=c(mm2,as.numeric((nuisance[sel2])))
             

                  X11=as.matrix(X[1:ns[1],]);
                  X22=as.matrix(X[(ns[1]+1):(ns[2]+ns[1]),]);
  

                   if(is.null(ns))  {sim <- c(X11%*%mm1,
                                              X22%*%mm2) + simd }
                  else            sim <- c(rep(as.numeric(nuisance['mean_1']),ns[1]),
                                         rep(as.numeric(nuisance['mean_2']),ns[2])) + simd 
                  }

            if(!spacetime&&!bivariate) sim <- c(sim)
            else sim <- matrix(sim, nrow=numtime, ncol=numcoord,byrow=TRUE)
       #   } 
       
        return(sim)
    }
####################################################################
############# END internal functions ###############################
####################################################################
    corrmodel=gsub("[[:blank:]]", "",corrmodel)
    model=gsub("[[:blank:]]", "",model)
    distance=gsub("[[:blank:]]", "",distance)
    method=gsub("[[:blank:]]", "",method)
    
    if(grid) { xgrid=coordx;ygrid=coordy;
               numxgrid=length(xgrid);numygrid=length(ygrid) }

    spacetime_dyn=FALSE
    ##############################################################################
    ##############################################################################
    bivariate<-CheckBiv(CkCorrModel(corrmodel))
    spacetime<-CheckST(CkCorrModel(corrmodel))
    if(!is.null(coordx_dyn))  spacetime_dyn=TRUE
   ################################################################################
    unname(coordt);
    if(is.null(coordx_dyn)){
    unname(coordx);unname(coordy)}
  ################################################################################ 
  ################ setting parameters for each model #############################
  ################################################################################
     if(!bivariate)
    {  sel=substr(names(param),1,4)=="mean"; 
       num_betas=sum(sel)   ## number of covariates
    }
   if(bivariate)
    {  sel1=substr(names(param),1,6)=="mean_1"; 
       num_betas1=sum(sel1)
       sel2=substr(names(param),1,6)=="mean_2"; 
       num_betas2=sum(sel2)
     num_betas=c(num_betas1,num_betas2) 
    }

    k=1
#################################
    if(model %in% c("SkewGaussian","SkewGauss","Beta",'Kumaraswamy','LogGaussian',
                    "StudentT","SkewStudentT","Poisson","poisson","TwoPieceTukeyh","Poisson",
                     "TwoPieceBimodal", "TwoPieceStudentT","TwoPieceGaussian","TwoPieceGauss","Tukeyh","Tukeyh2","Tukeygh","SinhAsinh",
                    "Gamma","Weibull",
                    "LogLogistic","Logistic")) 
       {
        if(spacetime_dyn){
          env <- new.env()
          #coords=do.call(rbind,args=c(coordx_dyn),envir = env) 
          if(is.list(X))  X=do.call(rbind,args=c(X),envir = env)}

  if(!bivariate){

           if(num_betas==1)  mm<-param$mean
           if(num_betas>1)   mm<- X%*%as.numeric((param[sel]))
           param$mean=0;if(num_betas>1) {for(i in 1:(num_betas-1)) param[[paste("mean",i,sep="")]]=0}


        if((model %in% c("SkewGaussian","SkewGauss","TwoPieceGaussian",
          "TwoPieceGauss","Gamma","Weibull","LogLogistic","Poisson","Tukeyh","Tukeyh2",
          'LogGaussian',"TwoPieceTukeyh","TwoPieceBimodal", "Tukeygh","SinhAsinh",
                    "StudentT","SkewStudentT","TwoPieceStudentT","Gaussian")))   ## 
        {
          vv<-param$sill;
          param$sill=1#-param$nugget
        }
        if(model%in% c("SkewGaussian","SkewGauss","SkewStudentT","TwoPieceTukeyh","TwoPieceBimodal", 
               "TwoPieceStudentT","TwoPieceGaussian","TwoPieceGauss"))
               { sk<-param$skew

               if(model%in% c("TwoPieceTukeyh")) tl<-param$tail
               if(model%in% c("TwoPieceBimodal")) bimo<-param$shape
               }
        }
        else {
           if(num_betas[1]==1) {mm1<-param$mean_1;param$mean_1=0}
            if(num_betas[1]>1)   mm1<- X%*%as.numeric((param[sel1])) 
            if(num_betas[2]==1) {mm2<-param$mean_2;param$mean_2=0}
            if(num_betas[2]>1)   mm2<- X%*%as.numeric((param[sel2])) 

            mm=c(mm1,mm2)
            vv1<-param$sill_1;param$sill_1=1-param$nugget_1;
            vv2<-param$sill_2;param$sill_2=1-param$nugget_2;;vv=c(vv1,vv2)
            sk1<-param$skew_1;sk2<-param$skew_2;sk=c(sk1,sk2)
        }}
#################################
  if(model %in% c("Tukeygh","SinhAsinh"))  {
         if(!bivariate){
          param$mean=0
          sk<-param$skew; tl<-param$tail}
         else {
            mm1<-param$mean_1;param$mean_1=0; mm2<-param$mean_2;param$mean_2=0;mm=c(mm1,mm2)
            vv1<-param$sill_1;param$sill_1=1;vv2<-param$sill_2;param$sill_2=1;vv=c(vv1,vv2)
            sk1<-param$skew_1;sk2<-param$skew_2;sk=c(sk1,sk2)
            tl1<-param$tail_1;tl2<-param$tail_2;sk=c(tl1,tl2)
        }}

    if(model %in% c("Tukeyh"))  {
         if(!bivariate){
          param$mean=0
          tl<-param$tail}
         else {
            mm1<-param$mean_1;param$mean_1=0; mm2<-param$mean_2;param$mean_2=0;mm=c(mm1,mm2)
            vv1<-param$sill_1;param$sill_1=1;vv2<-param$sill_2;param$sill_2=1;vv=c(vv1,vv2)
            tl1<-param$tail_1;tl2<-param$tail_2;sk=c(tl1,tl2)
        }}

         if(model %in% c("Tukeyh2"))  {
         if(!bivariate){
          param$mean=0
          t1l<-param$tail1
          t2l<-param$tail2
           }
        # else {
         #   mm1<-param$mean_1;param$mean_1=0; mm2<-param$mean_2;param$mean_2=0;mm=c(mm1,mm2)
          #  vv1<-param$sill_1;param$sill_1=1;vv2<-param$sill_2;param$sill_2=1;vv=c(vv1,vv2)
           # tl1<-param$tail_1;tl2<-param$tail_2;sk=c(tl1,tl2) }
          }
#################################
   if(model %in% c("Wrapped"))  {
        k=2;
        if(!bivariate){
            if(num_betas==1) mm<-2*atan(param$mean)+pi;   
            if(num_betas>1)  mm<-2*atan(X%*%as.numeric((param[sel])))+pi;
            param$mean=0    
            if(num_betas>1) {for(i in 1:(num_betas-1)) param[[paste("mean",i,sep="")]]=0}}
        else {
            mm1<-2*atan(param$mean_1)+pi;param$mean_1=0;
            mm2<-2*atan(param$mean_2)+pi;param$mean_2=0;
            mm=c(mm1,mm2)
            if(num_betas1>1) {for(i in 1:(num_betas1-1)) param[[paste("mean_1",i,sep="")]]=0}
            if(num_betas2>1) {for(i in 1:(num_betas2-1)) param[[paste("mean_2",i,sep="")]]=0}
        }} 
     
    npoi=1
################################# how many random fields ################
    if(model %in% c("LogGaussian")) k=1 
    if(model %in% c("SkewGaussian","SkewGauss","Weibull","TwoPieceGaussian","TwoPieceGauss","TwoPieceTukeyh")) k=2 
    if(model %in% c("LogLogistic","Logistic")) k=4 
    if(model %in% c("Binomial"))   k=round(n)
    if(model %in% c("Geometric","BinomialNeg")){ k=99999;
                                                 if(model %in% c("Geometric")) {model="BinomialNeg";n=1}
                                               } 
    if(model %in% c("Poisson")) {k=2;npoi=999999999}
    if(model %in% c("Gamma"))  {
                             if(!bivariate) k=round(param$shape)
                             if(bivariate)  k=max(param$shape_1,param$shape_2)
                               } 
    if(model %in% c("Beta"))  {k=round(param$shape1)+round(param$shape2);}
    if(model %in% c("Kumaraswamy"))  k=4
    if(model %in% c("StudentT"))  k=round(1/param$df)+1
    if(model %in% c("TwoPieceBimodal"))  k=round(param$df)+1
    if(model %in% c("SkewStudentT","TwoPieceStudentT"))  k=round(1/param$df)+2
     #if(model %in% c("Beta")) {  k=round(param$shape1)+round(param$shape2)       
       #  if(!bivariate) {  mm<-param$mean;param$mean=0
        #     vv<-param$sill;param$sill=1 }} 


  ################################################################################ 
  ################################################################################ 
   ns=NULL
   if(spacetime_dyn) {
        coords=NULL
       if(bivariate) coordt=c(1,2)
       coords=do.call(rbind,args=c(coordx_dyn))      
       ns=lengths(coordx_dyn)/2 
       coordx <- coords[,1]; coordy <- coords[,2]
       dime=sum(ns)
   }
   else { dime=ddim(coordx,coordy,coordt) 
          if(bivariate) {ns=c(length(coordx),length(coordx))/2}
        }
 
   if(!bivariate) dd=array(0,dim=c(dime,1,k)) 
   if(bivariate)  dd=array(0,dim=c(dime,2,k))    
   cumu=NULL;#s=0 # for negative binomial  case
 #########################################
 
#### computing correlation matrix  of the Gaussian random field
ccov = GeoCovmatrix(coordx, coordy, coordt, coordx_dyn, corrmodel, distance, grid,NULL,NULL, "Gaussian", n, 
                forGaussparam(model,param,bivariate), radius, sparse,NULL,NULL,"Standard",X)
    if(spacetime_dyn) ccov$numtime=1
    numcoord=ccov$numcoord;numtime=ccov$numtime;
    dime<-numcoord*numtime
    xx=double(dime)
    varcov<-ccov$covmat;  ######covariance matrix!!
######################################################### 
KK=1;sel=NULL;ssp=double(dime)


  while(KK<=npoi) { 
  for(i in 1:k) {  

    ss=matrix(rnorm(dime) , nrow=dime, ncol = 1)
   #### simulating with cholesky decomposition using GPU
    if(!is.null(GPU)&&sparse) sparse=FALSE   ### if gpu no sparse 

    if(!is.null(GPU)) {  ## todo...
                         ## here we wave to set the context!!!
                         ## setContext(id=3L)  example
                         ##varcov=gpuR::vclMatrix(varcov, type="float")
                         ##ss=gpuR::vclMatrix(ss, type="float")
                       }

    #### simulating with matrix decomposition using sparse or dense matrices
    if(sparse) {  
                  if(spam::is.spam(ccov$covmat))
                    simd=as.numeric(spam::rmvnorm.spam(1,mu=rep(0, dime), ccov$covmat) )
                  else
                  simd=as.numeric(spam::rmvnorm.spam(1,mu=rep(0, dime), spam::as.spam(ccov$covmat)) )
               }
    else
    {
        decompvarcov <- MatDecomp(varcov,method)
        if(is.logical(decompvarcov)){print(" Covariance matrix is not positive definite");stop()}
        sqrtvarcov <- MatSqrt(decompvarcov,method)
       if(!is.null(GPU)) simd=(gpuR::crossprod(sqrtvarcov,ss))# []
       else simd=crossprod(sqrtvarcov,ss)
    }
    #######################################################################
    nuisance<-param[ccov$namesnuis]
    if(i==1&&(model=="SkewGaussian"||model=="SkewGauss")&&bivariate) ccov$param["pcol"]=0
    ####################################
    #####formatting simulation #########

    sim<-RFfct1(ccov,dime,nuisance,param,simd,ccov$X,ns)
    ####################################
    ####### starting cases #############
    ####################################
 
    if(model %in% c("Binomial", "BinomialNeg")) {    
        simdim <- dim(sim)
        sim <- as.numeric(sim>0)
        dim(sim) <- simdim
         }
    ####################################    
    if(model %in% c("Weibull","SkewGaussian","SkewGauss","Binomial","Poisson","Beta","Kumaraswamy"
              ,"LogGaussian","TwoPieceTukeyh",
                "Gamma","LogLogistic","Logistic","StudentT",
                "SkewStudentT","TwoPieceStudentT","TwoPieceGaussian","TwoPieceGauss","TwoPieceBimodal")) {
       if(!bivariate) dd[,,i]=t(sim)
       if(bivariate)  dd[,,i]=t(sim)
  }
     ####################################     
    if(model %in% c("BinomialNeg")){ 
                 cumu=rbind(cumu,c(sim));
                 if(sum(colSums(cumu)>=n)==dime) {break;}### checking if at least n success have ben achived
               }
    }
     ####################################
  if(model %in% c("poisson","Poisson"))   { 
  pois1=0.5*(dd[,,1]^2+dd[,,2]^2)
   ssp=ssp+c(pois1)
  sel=rbind(sel,ssp<=c(exp(mm)))
  if(sum(apply(sel,2,prod))==0) break  ## stopping rule
 
}
 KK=KK+1
}

 ####### end for #########################  


 ###############################################################################################
 #### simulation for discrete random field based on indipendent copies  of GRF ######
 ###############################################################################################
 if(model %in% c("Binomial","Poisson","BinomialNeg"))   {

   if(model %in% c("poisson","Poisson"))   {sim=colSums(sel);byrow=TRUE}
########################################
   if(model %in% c("Binomial"))   { 
                  sim[sim==1]=0;
                  sim=c(sim)
                  for(i in 1:k) sim=sim+dd[,,i]
                  byrow=TRUE }
#######################################
   if(model %in% c("BinomialNeg"))   {
          sim=NULL
          for(p in 1:dime) sim=c(sim,which(cumu[,p]>0,arr.ind=T)[n]-n)
          byrow=FALSE
          }
############################################# 
############### formatting data #############
#############################################
    if(!grid)  {
                if(!spacetime&&!bivariate) sim <- c(sim)
                else                       sim <- matrix(sim, nrow=numtime, ncol=numcoord,byrow=byrow)
        }
    else{
        if(!spacetime&&!bivariate)  sim <- array(sim, c(numxgrid,numygrid))
        else                        sim <- array(sim, c(numxgrid,numygrid, numtime)) 
            }
}   
#########################################################################################################
#### simulation for continuos random field  (on the real line) based on indipendent copies  of GRF ######
#########################################################################################################

if(model %in% c("SkewGaussian","SkewGauss","SkewStudentT","StudentT","TwoPieceGaussian","TwoPieceGauss",
  "TwoPieceTukeyh","TwoPieceBimodal","TwoPieceStudentT"))   {


if(model %in% c("SkewGaussian","SkewGauss"))   {
        if(!bivariate) aa=mm+sk*abs(dd[,,1])+sqrt(vv)*dd[,,2]
        if(bivariate)  {aa=cbind(mm[1]+sk[1]*abs(dd[,,1][,1])+sqrt(vv[1])*dd[,,2][,1],
                                  mm[2]+sk[2]*abs(dd[,,1][,2])+sqrt(vv[2])*dd[,,2][,2])}
        }
################################################
if(model %in% c("SkewStudentT"))   { 
     sim=NULL
     for(i in 1:(k-2))  sim=cbind(sim,dd[,,i]^2)
        bb= sk*abs(dd[,,k-1])+dd[,,k]*sqrt(1-sk^2)
        aa=mm+sqrt(vv)*(bb/sqrt(rowSums(sim)/(k-2)))
        }    
################################################        
if(model %in% c("StudentT"))   { 
     sim=NULL
     for(i in 1:(k-1))  sim=cbind(sim,dd[,,i]^2)
        aa=mm+sqrt(vv)*(c(dd[,,k])/sqrt(rowSums(sim)/(k-1)))
        }
################################################
if(model %in% c("TwoPieceGaussian","TwoPieceGauss"))   { 
        sim=dd[,,1]
        discrete=dd[,,2] 
        pp=qnorm((1-sk)/2)
        sel=(discrete<=pp);discrete[sel]=1-sk;discrete[!sel]=-1-sk;
        aa=mm+sqrt(vv)*(abs(sim)*discrete)
        }
################################################ 
if(model %in% c("TwoPieceTukeyh"))   { 
        sim=dd[,,1]
        sim=sim*exp(tl*sim^2/2)
        discrete=dd[,,2] 
        pp=qnorm((1-sk)/2)
        sel=(discrete<=pp);discrete[sel]=1-sk;discrete[!sel]=-1-sk;
        aa=mm+sqrt(vv)*(abs(sim)*discrete)
        }
################################################ 
if(model %in% c("TwoPieceBimodal"))   { 
     sim=NULL
     for(i in 1:(k-1))  sim=cbind(sim,dd[,,i]^2)
        alpha=2*(bimo+1)/(k-1)
        sim=rowSums(sim)/2^(1-alpha/2);
        pp=qnorm((1-sk)/2)
        discrete=dd[,,k] 
        sel=(discrete<=pp);discrete[sel]=1-sk;discrete[!sel]=-1-sk;
        aa=mm+sqrt(vv)*(sim)^(1/alpha)*discrete
        #aa=mm+sqrt(vv)*(sim)^(1/bimo)*discrete
        }
################################################
if(model %in% c("TwoPieceStudentT"))   { 
     sim=NULL
     for(i in 1:(k-2))  sim=cbind(sim,dd[,,i]^2)

        aa=(c(dd[,,k-1])/sqrt(rowSums(sim)/(k-2)))
        pp=qnorm((1-sk)/2)
        discrete=dd[,,k] 
        sel=(discrete<=pp);discrete[sel]=1-sk;discrete[!sel]=-1-sk;
        aa=mm+sqrt(vv)*(abs(aa)*discrete)
        }
############################################# 
############### formatting data #############
#############################################
    if(!grid)  {
                if(!spacetime&&!bivariate) sim <- c(aa)
                else                       sim <- matrix(aa, nrow=numtime, ncol=numcoord,byrow=TRUE)
        }
         else{
        if(!spacetime&&!bivariate)  sim <- array(aa, c(numxgrid,numygrid))
        else                        sim <- array(aa, c(numxgrid,numygrid, numtime)) 
            }
}



#########################################################################################################
#### simulation for continuos random field  (on the positive real line) based on indipendent copies  of GRF ######
#########################################################################################################
if(model %in% c("LogLogistic","Logistic"))   { 
      sim1=sim2=NULL
    for(i in 1:2)  sim1=cbind(sim1,dd[,,i]^2)
    for(i in 3:4)  sim2=cbind(sim2,dd[,,i]^2)
     sim1=rowSums(sim1)/2; sim2=rowSums(sim2)/2;
     ######################################################
      if(model %in% c("LogLogistic"))   
       sim=exp(mm)*(sim1/sim2)^((1/param$shape))/(gamma(1+1/param$shape)*gamma(1-1/param$shape))
    if(model %in% c("Logistic"))   
       sim=mm+log(sim1/sim2)*(param$sill)^(0.5)   
  if(!grid)  {
                if(!spacetime&&!bivariate) sim <- c(sim)
                else                       sim <- matrix(sim, nrow=numtime, ncol=numcoord,byrow=TRUE)
        }
         else{
        if(!spacetime&&!bivariate)  sim <- array(sim, c(numxgrid,numygrid))
        else                        sim <- array(sim, c(numxgrid,numygrid, numtime)) 
            }
}

#######################################
if(model %in% c("Gamma","Weibull"))   { 

      sim=sim1=sim2=NULL;
    if(!bivariate) for(i in 1:k)  sim=cbind(sim,dd[,,i]^2)
    if(bivariate)  {for(i in 1:k)  sim1=cbind(sim1,dd[,,i][,1]^2)
                    for(i in 1:k)  sim2=cbind(sim2,dd[,,i][,2]^2)
                   }
     ######################################################
      if(model %in% c("Weibull"))   
           {
             if(!bivariate)   sim=exp(mm)*(rowSums(sim)/2)^(1/param$shape)/(gamma(1+1/param$shape))
             if(bivariate)    sim=cbind(
                                  exp(mm[1])*(rowSums(sim1)/2)^(1/param$shape_1)/(gamma(1+1/param$shape_1)),
                                  exp(mm[2])*(rowSums(sim2)/2)^(1/param$shape_2)/(gamma(1+1/param$shape_2)))
           }     
      if(model %in% c("Gamma"))  
      { 
      if(!bivariate) sim=exp(mm)*rowSums(sim)/k      

      if(bivariate){ 
        if(param$shape_1==param$shape_2){
                  sim=cbind(exp(mm[1])*rowSums(sim1)/param$shape_1,
                               exp(mm[2])*rowSums(sim2)/param$shape_2)}
        
        if(param$shape_1>param$shape_2){
                  aa=0
                  for(cc in 1:(param$shape_2)) aa=aa+sim2[,cc]
                  sim=cbind(exp(mm[1])*rowSums(sim1)/param$shape_1,
                            exp(mm[2])* aa/param$shape_2)}
       if(param$shape_1<param$shape_2){
                  aa=0
                  for(cc in 1:(param$shape_1)) aa=aa+sim1[,cc]
                  sim=cbind( exp(mm[1])* aa/param$shape_1,
                             exp(mm[2])*rowSums(sim2)/param$shape_2)}

        }
  }
############################################# 
############### formatting data #############
#############################################  
         if(!grid)  {
                if(!spacetime&&!bivariate) sim <- c(sim)
                else                       sim <- matrix(sim, nrow=numtime, ncol=numcoord,byrow=TRUE)
        }
         else{
        if(!spacetime&&!bivariate)  sim <- array(sim, c(numxgrid,numygrid))
        else                        sim <- array(sim, c(numxgrid,numygrid, numtime)) 
            }
}
#########################################################################################################
#### simulation for continuos random field  based  on a compact support based on indipendent copies  of GRF ######
#########################################################################################################
if(model %in% c("Beta","Kumaraswamy"))   { 
     sim1=NULL;sim2=NULL
      i=1
    if(model=="Beta")
    {
    while(i<=round(param$shape1))  {sim1=cbind(sim1,dd[,,i]^2);i=i+1}
    while(i<=(round(param$shape1)+round(param$shape2)))  {sim2=cbind(sim2,dd[,,i]^2);i=i+1}
    aa=rowSums(sim1)
    #sim=aa/(aa+rowSums(sim2)) 
   sim=param$min + (param$max-param$min)*aa/(aa+rowSums(sim2))  
    }
     if(model=="Kumaraswamy")
    {
    while(i<=2)  {sim1=cbind(sim1,dd[,,i]^2);i=i+1}
    while(i<=4)  {sim2=cbind(sim2,dd[,,i]^2);i=i+1}
    aa=rowSums(sim1)
    sim=aa/(aa+rowSums(sim2)) 
   # sim=( (1-(1-sim)^(1/param$shape1))^(1/param$shape2) )
    sim=param$min + (param$max-param$min)*( (1-(1-sim)^(1/param$shape1))^(1/param$shape2) )
    }   
         if(!grid)  {
                if(!spacetime&&!bivariate) sim <- c(sim)
                else                       sim <- matrix(sim, nrow=numtime, ncol=numcoord,byrow=TRUE)
        }
         else{
        if(!spacetime&&!bivariate)  sim <- array(sim, c(numxgrid,numygrid))
        else                        sim <- array(sim, c(numxgrid,numygrid, numtime)) 
            }
        }
    #######################################
    if(model %in% c("Wrapped"))   {
        if(spacetime) mm=matrix(mm,nrow=nrow(sim),ncol=ncol(sim),byrow=TRUE)
        sim=(sim+mm)%%(2*pi)
      }

 ###########################################################
 #### simulation based on a transformation of ONE standard (bivariate) GRF ######
 ###########################################################

if(model %in% c("Gaussian","LogGaussian","LogGauss","Tukeygh","Tukeyh","Tukeyh2","SinhAsinh"))
{
  sim=c(sim)
  
  if(model %in% c("LogGaussian","LogGauss"))   {     
        sim=exp(mm) *  (exp(sqrt(vv)*sim)/(exp( vv/2))) ## note the parametrization
        }      
#################################################################################
 if(model %in% c("Tukeygh"))   { 
     if(!sk && !tl) sim= mm+sqrt(vv)* sim
     if(!sk && tl)  sim= mm+sqrt(vv)* sim*exp(tl*sim^2/2)
     if(!tl && sk)  sim= mm+sqrt(vv)* (exp(sk*sim)-1)/sk
     if(tl&&sk)     sim= mm+sqrt(vv)* (exp(sk*sim)-1)*exp(0.5*tl*sim^2)/sk        
    }
############################################################################## 
  if(model %in% c("Tukeyh"))   { 
     if(!tl) sim= mm+sqrt(vv)*sim
     if(tl)  sim= mm+sqrt(vv)*sim*exp(tl*sim^2/2)
   }  

    if(model %in% c("Tukeyh2"))   { 
       sel=sim>0
       bb=sim*exp(t1l*sim^2/2)*as.numeric(sel);  bb[bb==0]=1
       aa=sim*exp(t2l*sim^2/2)*as.numeric(!sel); aa[aa==0]=1
      sim= mm+sqrt(vv)*(aa*bb)
   } 
#########################################
  if (model %in% c("SinhAsinh")) sim=mm+sqrt(vv)*sinh( (1/tl)*(asinh(sim)+sk))
 ### formatting data
  if(!grid)  {
                if(!spacetime&&!bivariate) sim <- c(sim)
                else                       sim <- matrix(sim, nrow=numtime, ncol=numcoord)
        }
         else{
        if(!spacetime&&!bivariate)  sim <- array(sim, c(numxgrid,numygrid))
        else                        sim <- array(sim, c(numxgrid,numygrid, numtime)) 
            }
}


##################################################################
###########. formatting data for space time dynamic case. #########
    if(spacetime_dyn) {
                    sim_temp=list()
                    for(k in 1:length(coordt))
                       { if(k==1) {indx=1:(sum(ns[1:k]))}
                         if(k>1)    {indx=(sum(ns[1:(k-1)])+1):(sum(ns[1:k]))}
                         sim_temp[[k]]=c(sim)[indx] }
    sim=sim_temp     
    }
##################################################################
    #######################################
    if(ccov$bivariate)   ccov$numtime=1

    # Delete the global variables:
    # Return the objects list:
    GeoSim <- list(bivariate = bivariate,
    coordx = ccov$coordx,
    coordy = ccov$coordy,
    coordt = ccov$coordt,
    coordx_dyn =coordx_dyn,
    corrmodel = corrmodel,
    data = sim,
    distance = distance,
    grid = grid,
    model = model,
    n=n,
    numcoord = ccov$numcoord,
    numtime = ccov$numtime,
    param = ccov$param,
    radius = radius,
    randseed=.Random.seed,
    spacetime = spacetime,
    sparse=ccov$sparse,
    X=X)
#}
##############################################
    structure(c(GeoSim, call = call), class = c("GeoSim"))
}

