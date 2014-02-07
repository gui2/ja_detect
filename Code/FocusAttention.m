clear all;
close all;
path='../Data/results-context/';
pathtoread='../Data/results-context/*.txt';

files = dir(pathtoread);
frames_index=1;
k=1;
lastcontext =1;
prevcontext = 0;

prevpoint = {0,0,0,0};
point =  {0,0,0,0};
prevpoint2D= {0,0};
point2D =  {0,0};

%% loop
figure (5);
hold on;
contextnumber=1;
averagedistance=0;
diagonal = 0;

for file = files'
  gtfile =  fopen([path file.name],'r');
  display ([path file.name]);
  count = 0;
  len = 1;
  
  while(~feof(gtfile)); % go into the detections
    InputText=textscan(gtfile,'%s',1,'delimiter','\n');
    
    if ~isempty(InputText{1,1})
      i = textscan(char(InputText{1,1}),'%s',7,'delimiter','  ');
      b = textscan(char(InputText{1,1}),'%s',9,'delimiter','  ');
            
      d = b{1,1};
      frames(1,frames_index)=(str2num(d{1,1}));
      
      if ~strcmp(d{2, 1},'NaN')
        % get the trajectory point.
        point = {str2num(d{2, 1}),str2num(d{3, 1}),str2num(d{4, 1}),str2num(d{5, 1})};
        
        % extract the center of the trajectory
        point2D = { ceil(str2num(d{2, 1}) +( str2num(d{4, 1})/2)),ceil(str2num(d{3, 1}) +(str2num(d{5, 1})/2))};
        
        % euclidean distance between the previous point and the actual point
        D = norm(cell2mat(prevpoint2D) - cell2mat(point2D));
        averagedistance = (averagedistance+ D )/ 2;
        diagonal = (diagonal + sqrt (str2num(d{4, 1})+str2num(d{5, 1})))/2;
        cont = (str2num(d{7,1}))+1; % I need to add 1
                
        % when the context has changed
        if (~isequal (lastcontext , cont))
          % also verify that the box disapeared near the center
          % and that the chunk was long enough.
          % If this conditions are achieved, the patch was lost
          % and the new chunk should be stuck to the previous
          % one.
          if (prevlen >3 &&  D <15 )
            % disp ('Context has Changed and the distance is low');
            % plot(point2D{1,1},point2D{1,2},'k.','MarkerSize',20);
            % plot(prevpoint2D{1,1},prevpoint2D{1,2},'r.','MarkerSize',20);
            lastcontext = cont;
          else % cambio el contexto pero nada paso
            % contextual(lastcontext + prevcontext,1) =  len;
            contextual(prevcontext+contextnumber,1) =  len-1;
            contextual(prevcontext+contextnumber,2) = (str2num(d{1,1}));
            contextual(prevcontext+contextnumber,3) = averagedistance;
            contextual(prevcontext+contextnumber,4) = diagonal;
            diagonal = 0;
            averagedistance=0;
            contextnumber=contextnumber+1;
            len =1;
            lastcontext = cont;
          end;
        end;
        len =  len+1;%(str2num(d{8,1}));
      else
        contextual(prevcontext+contextnumber,1) =  len-1;
        contextual(prevcontext+contextnumber,2) = (str2num(d{1,1}));
        contextual(prevcontext+contextnumber,3) = averagedistance;
        contextual(prevcontext+contextnumber,4) = diagonal;
        diagonal =0;
        averagedistance=0;
        contextnumber=contextnumber+1;
        len =1;
                       
      end;
      prevpoint = point;
      prevpoint2D=point2D;
      k=k+1;
      prevlen=len;
    end;
  end;
  
  disp(count);
  lastcontext = lastcontext+1;
  contextual(contextnumber + prevcontext,1) =  3000;
  prevcontext = prevcontext+contextnumber;
  contextnumber=1;
  lastcontext =1;
  frames_index=frames_index+1;
  fclose(gtfile);
end


figure;
clf;
hold on

x = contextual(:,1) ;
plot (x,'k');
q=1;
for (e=1:length (contextual));
  if (contextual(e,1)==3000)
    text(e,100,files(q,1).name,'rotation',90,'fontSize',12);
    q=q+1;
  end;
end;
hold off;

%%  split into chunks
splits = [1; find(contextual == 3000); length(contextual)];

for (i = 1:length(splits)-1)
  lens{i} = contextual(splits(i):splits(i+1)-1) * (1/30);
end

lens = lens(1:33);

ages = cellfun(@(x) str2num(x(4:5)), {files.name})

%% graph each individual histogram
figure(2)
clf
cols = {[1 0 0],[0 1 0],[0 0 1]};

for i = 1:length(lens)
  these_lens = lens{i};
  mlens(i) = mean(lens{i});
  medlens(i) = median(lens{i});
  %e = std(y)*ones(size(x));
  % these_lens = these_lens(these_lens > 1);
  subplot(6,6,i)
  cla
  bins = [0:.2:2];
  cs = hist(these_lens,bins);
  cs = cs ./ sum(cs);
  bar(bins,cs,'FaceColor',cols{(ages(i)-4)/4})
  axis([-.2 2 0 .3])
  ylabel('count')
  xlabel('time (s)')
  title(ages(i))
end

%% graph across ages
sem  = @(x ) nanstd(x) / size(x,2);

figure(4)
clf
cols = {[1 0 0],[0 1 0],[0 0 1]};
j= 1; c = 1;
age_grps = unique(ages);
clear css; clear ms;

for i = 1:length(lens)
  these_lens = lens{i};
  subplot(1,3,j)
  
  title(age_grps(j))
  bins = 10.^[-1:.1:1.3];
  cs = hist(these_lens,bins);
  cs = cs
  cs = cs ./ sum(cs);
  loglog(bins,cs,'LineWidth',3)
  hold on;
  
  axis([-1 20 0.000001 1.1])
  ylabel('count')
  xlabel('time (s)')
  css(c,:) = cs;
  c = c + 1;
  
  if i > 1 && ages(i) > ages(i-1)
    ms(j,:) = nanmean(css);
    mse(j,:) = sem(css)
    clear css
    loglog(bins,ms(j,:),'k','LineWidth',3)
    j = j + 1;
    c = 1;
  end
end

ms(j,:) = nanmean(css);
mse(j,:) = sem(css);
loglog(bins,ms(j,:),'k','LineWidth',3)

%% plot means
figure(6)
clf
loglog(bins,ms,'-o','LineWidth',2)
hold on
cols= {'b','g','r'};
% for i=1:3
%     errorbar(bins+bins*i*.02,ms(i,:),ms(i,:)-mse(i,:),ms(i,:)+mse(i,:),...
%         [cols{i} '.'],'MarkerSize',0.1)
% end
axis([-1 20 0.000001 1.1])

legend('8 months','12 months','16 months')
xlabel('Fixation time (s)','FontSize',15)
ylabel('Proportion fixations','FontSize',15)

%% now aggregate all of these by age
mlen = [mean(mlens(ages==8)) ...
  mean(mlens(ages==12)) ...
  mean(mlens(ages==16))];

medlen = [mean(medlens(ages==8)) ...
  mean(medlens(ages==12)) ...
  mean(medlens(ages==16))];

deviation = [sem(medlens(ages==8)) ...
  sem(medlens(ages==12)) ...
  sem(medlens(ages==16))];

figure(3)
clf
h = bar([8 12 16],mlen)
hold on
errorbar([8 12 16],mlen,mlen+deviation,mlen-deviation,'k.','MarkerSize',0.1,'LineWidth',3)
xlabel('Age (months)')
ylabel('Mean episode length (s)')

