%% set_params
%opts.num_folder : the number of identities
%opts.id_Persons : intermediate variable
%opts.numClasses : for test:gallery and probe,the number of identities in gallery and probe
%opts.g_num      : the number of groups for dictionary
%%
function opts = set_params(Dataset)
    switch Dataset
        case 'PRID 2011'
            opts.num_folder=178;
            opts.id_Persons=1:(opts.num_folder)/2;%1:89
            opts.numClasses=length(opts.id_Persons);%89
            opts.g_num=89; 
        case 'iLIDS-VID'
            opts.num_folder=300;
            opts.id_Persons=1:(opts.num_folder)/2;%1:150
            opts.numClasses=length(opts.id_Persons);%150
            opts.g_num=150;
        case 'SAIVT-SoftBio'
            opts.num_folder=103;
            opts.id_Persons=1:69;%1:69
            opts.numClasses=34;%for train
            opts.g_num=69;%for test           
        otherwise
            fprintf('Without this dataset,please select one from PRID 2011,iLIDS-VID and SAIVT-SoftBio!')
    end        
end

