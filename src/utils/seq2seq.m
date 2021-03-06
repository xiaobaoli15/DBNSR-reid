function [idx1,idx2,value]=estimate_label(X,cluster_num,g_num)
    col_avg_X=[];
    row_avg_X=[];
    for j=1:g_num
        each_avg_X=sum(X(:,(j-1)*cluster_num+1:j*cluster_num),2);
        col_avg_X=[col_avg_X each_avg_X];
    end
    for i=1:g_num
        each_avg_X=sum(col_avg_X((i-1)*cluster_num+1:i*cluster_num,:),1);
        row_avg_X=[row_avg_X;each_avg_X];    
    end
     avg_X=row_avg_X/(cluster_num*cluster_num);
     [value,idx]=sort(avg_X,'descend');

     %row1_value=value(1,:);
     row1_idx=idx(1,:);
     idx1=1:length(row1_idx);
     idx2=row1_idx;
end