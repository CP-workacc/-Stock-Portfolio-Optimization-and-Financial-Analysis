# Stock Market Case in R
rm(list=ls(all=T)) # this just removes everything from memory


# Connect to PostgreSQL ---------------------------------------------------

# Make sure you have created the reader role for our PostgreSQL database
# and granted that role SELECT rights to all tables
# Also, make sure that you have completed (or restored) Part 3b db

# ONLY IF YOU STILL AN AUTHENTICATION ERROR:
# Try changing the authentication method from scram-sha-256 to md5 or trust (note: trust is not a secure connection, use only for the purpose of completing the class)
# this is done by editing the last lines of the pg_hba.conf file,
# which is stored in C:\Program Files\PostgreSQL\16\data (for version 16)
# Restart the computer after the change

#start of project code

require(RPostgres) # did you install this package?
require(DBI)
conn <- dbConnect(RPostgres::Postgres()
                 ,user="stockmarketreader"
                 ,password="read123"
                 ,host="localhost"
                 ,port=5432
                 ,dbname="stockmarket"
)

#custom calendar
qry<-'SELECT * FROM custom_calendar ORDER by date'
ccal<-dbGetQuery(conn,qry)
#eod prices and indices
qry1="SELECT symbol,date,adj_close FROM eod_indices WHERE date BETWEEN '2015-12-31' AND '2021-03-26'"
qry2="SELECT ticker,date,adj_close FROM eod_quotes WHERE date BETWEEN '2015-12-31' AND '2021-03-26'AND (ticker = 'SLF' or ticker = 'FBC' or ticker = 'ZNGA' or ticker = 'WM' or ticker = 'MLM' or ticker = 'HD' or ticker = 'CSOD' or ticker = 'IRM' or ticker = 'KMB' or ticker = 'PZN' or ticker = 'NP' or ticker = 'IDCC' or ticker = 'FELE' or ticker = 'GGB' or ticker = 'FAST')"
eod<-dbGetQuery(conn,paste(qry1,'UNION',qry2))
dbDisconnect(conn)
rm(conn)

#Explore
head(ccal)
tail(ccal)
nrow(ccal)

head(eod)
tail(eod)
nrow(eod)

#For monthly we may need one more data item (for 2015-12-31)
#We can add it to the database (INSERT INTO)
eod_row<-data.frame(symbol='SP500TR',date=as.Date('2015-12-31'),adj_close=3821.60)
eod<-rbind(eod,eod_row)
tail(eod)


# Use Calendar --------------------------------------------------------
tday<-ccal[which(ccal$trading==1),,drop=F] #selecting only trading days
head(tday)
tail(tday)
nrow(tday)-1 #trading days between 2016 and 2020 (excludes 12/31/2015)

# Completeness ----------------------------------------------------------
# Percentage of completeness
pct<-table(eod$symbol)/(nrow(tday)-1)
#POSSIBLE CHECK? SP500 has a % of 95.7% and therefore falls off if pct >= 0.99
#check here with professor
selected_symbols_monthly<-names(pct)[which(pct>=0.99)] #changed from 0.99 to 0.95
eod_complete<-eod[which(eod$symbol %in% selected_symbols_monthly),,drop=F]


#check
head(eod_complete)
tail(eod_complete)
nrow(eod_complete)


# Transform (Pivot) -------------------------------------------------------

require(reshape2) #did you install this package?
eod_pvt<-dcast(eod_complete, date ~ symbol,value.var='adj_close',fun.aggregate = mean, fill=NULL)
#check
eod_pvt[1:10,1:16] #first 10 rows and all columns 
ncol(eod_pvt) # column count
nrow(eod_pvt)
head(eod_pvt)
tail(eod_pvt)

# Merge with Calendar -----------------------------------------------------
eod_pvt_complete<-merge.data.frame(x=tday[,'date',drop=F],y=eod_pvt,by='date',all.x=T)

#check
eod_pvt_complete[1:10,1:17] #first 10 rows and all columns
ncol(eod_pvt_complete)
nrow(eod_pvt_complete)
head(eod_pvt_complete)
tail(eod_pvt_complete)

#use dates as row names and remove the date column
rownames(eod_pvt_complete)<-eod_pvt_complete$date
eod_pvt_complete$date<-NULL #remove the "date" column

#re-check
eod_pvt_complete[1:10,1:5] #first 10 rows and first 5 columns 
ncol(eod_pvt_complete)
nrow(eod_pvt_complete)

# Missing Data Imputation -----------------------------------------------------
# We can replace a few missing (NA or NaN) data items with previous data
require(zoo)
eod_pvt_complete<-na.locf(eod_pvt_complete,na.rm=F,fromLast=F,maxgap=3)
#re-check
eod_pvt_complete[1:10,1:16] #first 10 rows and first 5 columns 
ncol(eod_pvt_complete)
nrow(eod_pvt_complete)

# Calculating Returns -----------------------------------------------------
require(PerformanceAnalytics)
eod_ret<-CalculateReturns(eod_pvt_complete)

#check
eod_ret[1:10,1:3] #first 10 rows and first 3 columns 
ncol(eod_ret)
nrow(eod_ret)

#remove the first row
eod_ret<-tail(eod_ret,-1) #use tail with a negative value
#check
eod_ret[1:10,1:3] #first 10 rows and first 3 columns 
ncol(eod_ret)
nrow(eod_ret)

# Check for extreme returns -------------------------------------------
# There is colSums, colMeans but no colMax so we need to create it
colMax <- function(data) sapply(data, max, na.rm = TRUE)
# Apply it
max_daily_ret<-colMax(eod_ret)
max_daily_ret[1:10] #first 10 max returns
# And proceed just like we did with percentage (completeness)
selected_symbols_daily<-names(max_daily_ret)[which(max_daily_ret<=1.00)]
length(selected_symbols_daily)

#subset eod_ret
eod_ret<-eod_ret[,which(colnames(eod_ret) %in% selected_symbols_daily),drop=F]
#check
eod_ret[1:10,1:16] #first 10 rows and first 3 columns 
ncol(eod_ret)
nrow(eod_ret)

# Tabular Return Data Analytics -------------------------------------------

# We need to convert data frames to xts (extensible time series)
Ra<-as.xts(eod_ret[,c('CSOD','FAST','FBC','FELE','GGB','HD','IDCC','IRM','KMB', 'MLM','NP','PZN','SLF','WM','ZNGA'),drop=F])
Rb<-as.xts(eod_ret[,'SP500TR',drop=F]) #benchmark
head(Ra)
head(Rb)
tail(Rb)

# Returns
table.AnnualizedReturns(cbind(Rb,Ra),scale=252) # note for monthly use scale=12

# Accumulate Returns
acc_Ra<-Return.cumulative(Ra);acc_Ra
acc_Rb<-Return.cumulative(Rb);acc_Rb

# Cumulative returns chart
chart.CumReturns(Ra,legend.loc = 'topleft')
chart.CumReturns(Rb,legend.loc = 'topleft')

# MV Portfolio Optimization -----------------------------------------------

# withhold the last 58 trading days excludes 2021 dates we have
Ra_training<-head(Ra,-58) 
Rb_training<-head(Rb,-58)
tail(Ra_training)

# use the last 253 trading days for testing
Ra_testing<-tail(Ra,58)
Rb_testing<-tail(Rb,58)
head(Ra_testing)
tail(Ra_testing)

#optimize the MV (Markowitz 1950s) portfolio weights based on training
table.AnnualizedReturns(Rb_training) #annual minimum acceptable return
mar<-mean(Rb_training) #daily minimum acceptable return

require(PortfolioAnalytics)
require(ROI) # make sure to install it
require(ROI.plugin.quadprog)  # make sure to install it
pspec<-portfolio.spec(assets=colnames(Ra_training))
pspec<-add.objective(portfolio=pspec,type="risk",name='StdDev')
pspec<-add.constraint(portfolio=pspec,type="full_investment")
pspec<-add.constraint(portfolio=pspec,type="return",return_target=mar)

#optimize portfolio
opt_p<-optimize.portfolio(R=Ra_training,portfolio=pspec,optimize_method = 'ROI')

#extract weights (negative weights means shorting)
opt_w<-round(opt_p$weights, 4)

#apply weights to test returns
Rp<-Rb_testing # easier to apply the existing structure
#define new column that is the dot product of the two vectors
Rp$ptf<-Ra_testing %*% opt_w

#check
head(Rp)
tail(Rp)

#Compare basic metrics
table.AnnualizedReturns(Rp)

# Chart Hypothetical Portfolio Returns ------------------------------------

chart.CumReturns(Rp,legend.loc = 'bottomright')
