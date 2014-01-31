close all;
clear all; 

file = '/Users/Gui/ja_detect/Code/PartialMatrices/';
kids = {'0801','0805','0807','0811','0815','1604','1612','1622','1635'};

%% 10-fold NB classification 

for k = 1:length(kids)
    disp(kids{k})
    load ([file 'CLUS' kids{k} '-200.mat']);

    % load positive clusters
    d = [negCluster(:,4:9); positiveCluster(:,4:9)];
    gt_frame = [zeros(size(negCluster,1),1); ones(size(positiveCluster,1),1)];

    % average parameter weights
    descriptives(:,:,k) = [mean(d(~logical(gt_frame),3:6)~=0); ...
   mean(d(logical(gt_frame),3:6)~=0)];
    
    % classifier with 10-fold
    indices = crossvalind('Kfold', gt_frame, 10);

    for i = 1:10
        test = (indices==i); train = ~test;    
        nb = NaiveBayes.fit (d(train,:),gt_frame(train));
        preds = nb.predict(d(test,:));
        %cMat1 = confusionmat(gt_frame(test),preds) ;
        f = gt_frame(test);
        fold_avg(k,i) = mean(preds == gt_frame(test));
        
        % extract parameters
        for p = 1:9
            params(k,i,p,:) = nb.Params{p};
        end
    end
end

%% now look at results
fold_avg
mean(fold_avg,2)

m_params = squeeze(mean(params,2));

figure (1);
for i = 1:9
    subplot(3,3,i)
       colormap([1 0 0; 0 0 1]);
    bar(squeeze(m_params(i,:,:)))
    title(kids{i})
    legend('no JA','JA')
    set(gca,'XTickLabel',{'Chunk Length','Chunk Speed',...
        'Face Speed','Face Size','Object Speed','Object Size'});
    
end
%saveas(gcf, 'test.png')
export_fig /Users/Gui/ja_detect/CogSci14/Image/weights.pdf

figure (2);
for i = 1:9
    subplot(3,3,i)
 
    bar(descriptives(:,:,i)')
    title(kids{i})
    legend('no JA','JA')
    set(gca,'XTickLabel',{'Chunk Sp','Chunk Length',...
        'Face Sp','Face Sze','Object Speed','Object Size'});

end
xlabel('Sp = Speed;  L = Length;  Sze = Size   ')

%%
figure(3)
m_descriptives = mean(descriptives,3);
colormap([1 0 0; 0 0 1]);
subplot(1,2,1)
bar(m_descriptives(:,[2 4])')
set(gca,'XTickLabel',{'Face','Object'});
legend('no JA','JA','Location','NorthWest')
ylabel('Proportion feature presence')
title('Descriptive statistics')

subplot(1,2,2)
bar(squeeze(mean(m_params)))
legend('no JA','JA','Location','NorthWest')
set(gca,'XTickLabel',{'Chunk Length','Chunk Speed',...
    'Face Speed','Face Size','Object Speed','Object Size'});
ylabel('Parameter weight')
title('Mean Classifer Parameter Weights')
xlabel('Feature')
% 
% a=get(gca,'XTickLabel');
% set(gca,'XTickLabel',[]);
% b=get(gca,'XTick');
% c=get(gca,'YTick');
% rot=90;
% text(b,repmat(c(1)+2*(c(2)-c(1)),length(b),1),a,'HorizontalAlignment','right','rotation',rot,'FontSize', 13, 'FontWeight', 'normal');
% 
% set(gca,'ButtonDownFcn','selectmoveresize');
export_fig /Users/Gui/ja_detect/CogSci14/Image/individual.pdf
