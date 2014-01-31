% calculate precision, recall, and false alarms
function [p r f a] = calcPRF(resp,ans)
 
% acc (TP + TN) / (TP + TN + FP + FN)

hits = sum(resp==1 & ans==1);
misses = sum(resp==0 & ans==1);
false_alarms = sum(resp==1 & ans==0);
true_negatives = sum(resp==0 & ans==0);

p = hits / (hits + false_alarms);
r = hits / (hits + misses);
f = harmmean([p r],2);
a = (hits + true_negatives) / (hits + misses + true_negatives + false_alarms);