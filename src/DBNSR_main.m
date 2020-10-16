%DBNSR_main
clear;
close all;
set(0,'DefaultFigureWindowStyle','docked');
addpath('features/PRID 2011/GOG');
addpath('features/iLIDS-VID/GOG');
addpath('database/train-test people splits');
addpath('LibADMM-master/algorithms');
addpath('LibADMM-master/proximal_operator');
addpath('MetricLearning/KISSME')
addpath('MetricLearning/KISSME/toolbox/learnAlgos')
addpath('MetricLearning/KISSME/toolbox/helper')
addpath('src/unsupervised_SR_method');
addpath('src/utils')
addpath('pca')
addpath('lib')

%% The parameters 
Dataset='iLIDS-VID';%{PRID 2011,iLIDS-VID,SAIVT-SoftBio}
feature_method='GOG';%{LOMO,GOG,HistLBP}    
metric_method='KISSME';%{'without_metric','XQDA','KISSME','MFA'}
do_cluster='1';%{0-without,1-with}
cluster_num=6; %the number of clusters
doPCA='1';%{0-without,1-do}
pca_ReducedDim=600;%PCA for feature reduction
Bi_unBi_mode='BNSR';%{'NSR','BNSR'}
supervised_mode='unsupervised';%{supervised,unsupervised}

%% load data
load_data;

%% Initialize para
opts = set_params(Dataset);
if isfield(opts,'num_folder'), num_folder=opts.num_folder; end
if isfield(opts,'id_Persons'), id_Persons=opts.id_Persons; end
if isfield(opts,'numClasses'), numClasses=opts.numClasses; end
if isfield(opts,'g_num'),      g_num=opts.g_num;           end

%% For PRID 2011, we select those identities of which contain >=21 frames, in camera_a and camera_b simutaneously
if strcmp(Dataset,'PRID 2011')
    counter=1;a_counter=1;b_counter=1;
    camA_each_seq_num=[];camB_each_seq_num=[];
    for ls=1:length(a_each_num)
        if (a_each_num(ls)>=21) && (b_each_num(ls)>=21)&&(counter<=178)
           tmp_a_feature=a_features(:,a_counter:a_counter+a_each_num(ls)-1);
           A_feature{counter}=tmp_a_feature;
           A_label{counter}=counter*ones(1,a_each_num(ls));%label
           tmp_b_feature=b_features(:,b_counter:b_counter+b_each_num(ls)-1);
           B_feature{counter}= tmp_b_feature;
           B_label{counter}=counter*ones(1,b_each_num(ls)); %label      
           counter=counter+1;
           camA_each_seq_num=cat(2,camA_each_seq_num,a_each_num(ls));
           camB_each_seq_num=cat(2,camB_each_seq_num,b_each_num(ls));
        end
        a_counter=a_counter+a_each_num(ls);
        b_counter=b_counter+b_each_num(ls);
        if counter>178
           break;
        end
    end
else
    counter=1;a_counter=1;b_counter=1;
    camA_each_seq_num=[];camB_each_seq_num=[];
    for ls=1:length(a_each_num)
       tmp_a_feature=a_features(:,a_counter:a_counter+a_each_num(ls)-1);
       A_feature{counter}=tmp_a_feature;
       A_label{counter}=counter*ones(1,a_each_num(ls));
       tmp_b_feature=b_features(:,b_counter:b_counter+b_each_num(ls)-1);
       B_feature{counter}= tmp_b_feature;
       B_label{counter}=counter*ones(1,b_each_num(ls));    
       counter=counter+1;
       camA_each_seq_num=cat(2,camA_each_seq_num,a_each_num(ls));
       camB_each_seq_num=cat(2,camB_each_seq_num,b_each_num(ls));
       a_counter=a_counter+a_each_num(ls);
       b_counter=b_counter+b_each_num(ls);
    end
end

%% CMC
CMC_mean = zeros(10,size(ls_set,2)/2); 
Gallery_Labels=[];
for i=1:g_num
    Gallery_Labels=[Gallery_Labels i*ones(1,cluster_num)];
end

%% repeat 10 trails
for iter_trail=1:10
    p=ls_set(iter_trail,:);
    tmp_Probe= cat(2,A_feature{p(1:g_num)});
    tmp_Gallery=cat(2,B_feature{p(1:g_num)});
    tmp_a_Train=cat(2,A_feature{p(g_num+1:end)});
    tmp_b_Train=cat(2,B_feature{p(g_num+1:end)});
    
    cur_camA_each_seq_num= camA_each_seq_num(p);
    cur_camB_each_seq_num= camB_each_seq_num(p);
   %% pca   
   if strcmp(doPCA,'1')
       fprintf('PCA----->>');
       FeatTrn_ori_1 = [tmp_a_Train, tmp_b_Train];  
       meanTrn = mean(FeatTrn_ori_1, 2);
       options.ReducedDim = pca_ReducedDim;
       [W, ux] = myPCA(FeatTrn_ori_1', options);  %W:26960(7567)*600   ux:600*1
       tmp_a_Train = W'*(tmp_a_Train - repmat(meanTrn, [1, size(tmp_a_Train, 2)]));
       tmp_b_Train = W'*(tmp_b_Train - repmat(meanTrn, [1, size(tmp_b_Train, 2)]));
       tmp_Probe = W'*(tmp_Probe - repmat(meanTrn, [1, size(tmp_Probe, 2)]));  
       tmp_Gallery = W'*(tmp_Gallery - repmat(meanTrn, [1, size(tmp_Gallery, 2)]));
   end
   %% clustering    
    fprintf('Clustering----->>');  

    means_Probe=Clustering(tmp_Probe,cluster_num,g_num,cur_camA_each_seq_num(1:g_num),do_cluster);
    means_Gallery=Clustering(tmp_Gallery,cluster_num,g_num,cur_camB_each_seq_num(1:g_num),do_cluster);
    means_a_Train=Clustering(tmp_a_Train,cluster_num,numClasses,cur_camA_each_seq_num(g_num+1:end),do_cluster);
    means_b_Train=Clustering(tmp_b_Train,cluster_num,numClasses,cur_camB_each_seq_num(g_num+1:end),do_cluster);

    [means_a_Train,~]=normalizeBase(means_a_Train);
    [means_b_Train,~]=normalizeBase(means_b_Train);
    [means_Probe,~]=normalizeBase(means_Probe);
    [means_Gallery,~]=normalizeBase(means_Gallery);
    
    means_a_Train_cell=feature_mat2cell(means_a_Train,ones(1,g_num)*cluster_num);
    means_b_Train_cell=feature_mat2cell(means_b_Train,ones(1,g_num)*cluster_num);

    if strcmp(supervised_mode,'unsupervised')
       fprintf('Unsupervised');
       %shuffle
       a1=randperm(length(means_a_Train_cell));
       a2=randperm(length(means_b_Train_cell));
       means_a_Train_cell=means_a_Train_cell(a1);
       means_b_Train_cell=means_b_Train_cell(a2);
       [means_a_Train,~]=feature_cell2mat(means_a_Train_cell);
       [means_b_Train,~]=feature_cell2mat(means_b_Train_cell);
    end
    
    L=eye(pca_ReducedDim);
    pro_means_a_Train=means_a_Train;
    pro_means_b_Train=means_b_Train;
    
    %% DBNSR for label estimation
    for dynamic_iter=1:10  %the number of iterations
        % BNSR
        [X1,E1]=BNSR(pro_means_b_Train,pro_means_a_Train);
        [X2,E2]=BNSR(pro_means_a_Train,pro_means_b_Train);  
        
        %Label estimation based on BNSR
        [postive_idx1,postive_idx2]=label_estimation(X1,X2,cluster_num,g_num,Bi_unBi_mode);
        
        %generate training data with the estimated pairwise labels
        if strcmp(supervised_mode,'unsupervised')
             fprintf('Unsupervised--->>');
             Training_data=[];
             
             label_estimation_acc(a1,a2,postive_idx1,postive_idx2);
             
             means_a_Train_mat=feature_cell2mat(means_a_Train_cell(postive_idx1));
             means_b_Train_mat=feature_cell2mat(means_b_Train_cell(postive_idx2));
             Training_data=[means_b_Train_mat, means_a_Train_mat];

            %assign labels
             estimation_a_train_Labels=[];
             for estimation_iter=1:length(postive_idx2)
                 estimation_a_train_Labels=[estimation_a_train_Labels ones(1,cluster_num)*estimation_iter];
             end
             estimation_b_train_Labels=estimation_a_train_Labels;
             Training_labels=[estimation_b_train_Labels estimation_a_train_Labels];  
             a_train_Labels=estimation_a_train_Labels;
             b_train_Labels=estimation_b_train_Labels;
        else 
             fprintf('Supervised--->>');
             Training_data=[];
             postive_idx2=1:g_num;
             means_a_Train_mat=means_a_Train;
             means_b_Train_mat=means_b_Train;
             Training_data=[means_b_Train, means_a_Train];
              %label
             a_train_Labels=[];
             for target_label_iter=1:length(postive_idx2)%postive_idx
                 a_train_Labels=[a_train_Labels ones(1,cluster_num)*target_label_iter];
             end
             b_train_Labels=a_train_Labels;
             Training_labels=[b_train_Labels a_train_Labels];  
        end
        
        %% Metric learning
         switch metric_method
             case 'without_metric'
                 fprintf('%s----->>',metric_method);
                 pro_means_a_Train=means_a_Train;
                 pro_means_b_Train=means_b_Train; 
                 Gallery=means_Gallery;
                 Probe=means_Probe; 
             case 'MFA'
                 fprintf('%s----->>',metric_method);
                 AlgoOption.Nw = 0; % 0--use all within class samples
                 AlgoOption.Nb = 12;
                 AlgoOption.d = 200;
                 AlgoOption.beta = 0.01;
                 AlgoOption.epsilon =1e-6;
                 AlgoOption.kernel ='linear';  %chi2,linear
                 AlgoOption.dataname ='';  %chi2  
                 [Method,~]=  MFA(Training_data',Training_labels',AlgoOption);
                 [ker_Gallery] = ComputeKernelTest(Training_data',means_Gallery', Method);
                 [ker_Probe] = ComputeKernelTest(Training_data',means_Probe', Method);
                 [ker_means_a_Train] = ComputeKernelTest(Training_data',means_a_Train', Method);
                 [ker_means_b_Train] = ComputeKernelTest(Training_data',means_b_Train', Method);
                 T=Method.P;
                 
                 [pro_means_a_Train,~]=normalizeBase(T*ker_means_a_Train);%the feature demension size is different.
                 [pro_means_b_Train,~]=normalizeBase(T*ker_means_b_Train);  
                 [Gallery,~]=normalizeBase(T*ker_Gallery);
                 [Probe,~]=normalizeBase(T*ker_Probe);     
             case 'XQDA'
                 fprintf('%s----->>',metric_method);
                 [W, M] = XQDA(means_a_Train_mat' ,means_b_Train_mat',a_train_Labels',b_train_Labels');
                 %L=chol(M);
                 L=M;
                 [pro_means_a_Train,~]=normalizeBase(L*W'*means_a_Train);
                 [pro_means_b_Train,~]=normalizeBase(L*W'*means_b_Train);  
                 [Gallery,~]=normalizeBase(L*W'*means_Gallery);
                 [Probe,~]=normalizeBase(L*W'*means_Probe);
             case 'KISSME'
                 fprintf('%s----->>',metric_method);
                 %options.N=size(estimation_a_train_Labels,2); % not used actually
                 options.lambda=0.001;
                 options.npratio = 3;%
                 cHandle=LearnAlgoKISSME(options);
                 [pos_pairs,negtive_pairs]=split_neg_pos(length(postive_idx2),cluster_num);
                 pairs=[pos_pairs;negtive_pairs];

                 y = [ones(size(pos_pairs,1),1); ones(size(negtive_pairs,1),1).*(-1)];
                 s=learnPairwise(cHandle,double(Training_data),pairs(:,1),pairs(:,2),y>0);
                 ds.(cHandle.type)=s;
                 T=ds.kissme.M;
                 L=chol(T);     

                 [pro_means_a_Train,~]=normalizeBase(L*means_a_Train);%the feature demension size is different.
                 [pro_means_b_Train,~]=normalizeBase(L*means_b_Train);  

                 [Gallery,~]=normalizeBase(L*means_Gallery);
                 [Probe,~]=normalizeBase(L*means_Probe);  
             otherwise
                 fprintf('without this method,please choose another one.')
         end
        %% testing: Calculate the distance between each probe pedestrian and all pedestrians in the gallery 
        [Alphas,E]=Elasticnet(Gallery,Probe);
        
        %computing the sparse rapresentation residual
        sparse_rapresentation_res=sparseConstruct(Probe,Gallery,Alphas,id_Persons,Gallery_Labels,E); 
        
        %averaging the sparse rapresentation residual of each person sequence
        each_sequence_avg_res=[];
        for i=1:g_num
            each_sequence_res=sparse_rapresentation_res(:,(i-1)*cluster_num+1:i*cluster_num);
            each_sequence_avg_res=cat(2,each_sequence_avg_res,sum(each_sequence_res,2)./cluster_num);      
        end
        
        %% CMC
        mean_dist=each_sequence_avg_res;
        result_rank = calc_CMC(mean_dist);
        fprintf('%d|%d---->>',dynamic_iter,iter_trail);
        fprintf('Rank: %2.2f%%, %2.2f%%, %2.2f%%, %2.2f%%, %2.2f%%\n', (result_rank([1 5 10 15 20]))*100);
    end
    CMC_mean(iter_trail,:) = calc_CMC(mean_dist);
end%iter_trail end
cmc = mean(CMC_mean,1);
fprintf('Average Distance: %2.2f%%, %2.2f%%, %2.2f%%, %2.2f%%, %2.2f%%\n', (cmc([1 5 10 15 20]))*100);
