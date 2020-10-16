function [pos_pairs,negtive_pairs]=split_neg_pos(g_num,cluster_num)

N=g_num*cluster_num;
N_sequence=1:N;
negtive_pairs=[];

for i=1:g_num
    relative_positive=[(i-1)*cluster_num+1:i*cluster_num];
    relative_negtive=setdiff(N_sequence,relative_positive);
    neg_sequence=N+relative_negtive;
    rand_sequence_neg=neg_sequence(randperm(length(neg_sequence)));
    neg=rand_sequence_neg(1:cluster_num);
    rand_sequence_pos=relative_positive(randperm(length(relative_positive)));
    pos=rand_sequence_pos(1:cluster_num);
    tmp_negtive_pair=[pos' neg'];
    negtive_pairs=[negtive_pairs;tmp_negtive_pair];
end

a_index=1:N;
b_index=N+1:2*N;
tmp_pos_pairs=[a_index;b_index];
pos_pairs=tmp_pos_pairs';
end
    
    

    