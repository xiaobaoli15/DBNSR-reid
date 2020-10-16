%Bi_direction_select_pos_pairs
function [postive_idx1,postive_idx2]=label_estimation(X1,X2,cluster_num,g_num,Bi_unBi_mode)
     [idx11,idx12,value1]=seq2seq(X1,cluster_num,g_num);
     [idx21,idx22,value2]=seq2seq(X2,cluster_num,g_num);

     final_pos_idx=[];
     for ii=1:length(idx12)
         pos_idx=find(idx21==idx12(ii));
         if idx11(ii)==idx22(pos_idx)
            final_pos_idx=[final_pos_idx ii];
         end
     end
     if strcmp(Bi_unBi_mode,'BNSR')
         fprintf('%s--->>',Bi_unBi_mode);
         postive_idx1=idx11(final_pos_idx);
         postive_idx2=idx12(final_pos_idx);
     else %NSR
        fprintf('%s--->>',Bi_unBi_mode);
        row1_value=value1(1,:);
        postive_value_idx=find(row1_value>0.01);
        postive_idx1=idx11(postive_value_idx);
        postive_idx2=idx12(postive_value_idx);
     end
end


 