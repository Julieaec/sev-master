function scored_event_space = scoreEventspace_with_split_and_merge(interaction_matrix,threshold)
% updates the scoreEventspace method initially created by Hyatt Moore IV on
% 10/24/11.  
% This algorithm now accounts for the splitting or merging that occurs in
% scoring the event space by the greedy algorithm, which previously led to
% incorrect Kappa indices in connection with the within-bounds variable
% duration events. 

% applies a greedy algorithm to the interaction_matrix using the given
%threshold to determine the scored_event_space
%The greedy algorithm is described here - author Hyatt Moore IV 10/24/11
% For an interaction matrix of N rows and M columns,
%  1. Let R[i]C[events] represent the columns in the ith row that have an interaction score greater than 0.  
%  2. Let R[i]C[max] represent the element in R[i]C[events] that contains the largest interaction score.
%  3. repeat the following steps for each row beginning at the first row.
%       A.  Calculate the sum of the row as Rsum[i] where i corresponds to the ith row.
%       B.  Set all values in R[i] to zero.
%       C.  If Rsum[i] is greater than the threshold T
%           (1) Set all columns indexed by R[i]C[events] to zero.  
%           (2) Set the value of/at location R[i]C[max] to (RSum[i]-delete) a hit


scored_event_space = interaction_matrix*0;

for row_ind=1:size(interaction_matrix,1)
    Rsum = sum(interaction_matrix(row_ind,:));
    [~, Cmax_ind] = max(interaction_matrix(row_ind,:));
    if(Rsum>=threshold)
        scored_event_space(row_ind,Cmax_ind) = 1;
        interaction_matrix(:,interaction_matrix(row_ind,:)>0)=0; %zero out all other columns;
    end
end

