```{r, echo=TRUE, message=FALSE, warning=FALSE}
library(data.table)
library(dplyr)
library(stringi)
library(mirt)
library(foreign)
library(psych)
```

First of all, we read the csv file using the function "fread", provided by data.table, which enables fast reading of csv file.
```{r}
setwd('..')
dt = fread(file.path('extracted_data.csv'))
head(dt,3)
```



```{r, echo=TRUE, message=FALSE, warning=FALSE}
dt[,success:= result_flag<=2]
dt= rename(dt, same_p_optimal = p_optimal)
dt[, p_dup:=duplicates/optstep]
dt[,f_m_ratio:= first_move_time/rest_mean]
dt[,fp_m_ratio:= first_push_time/rest_mean]
dt[,f_t_ratio:= first_move_time/guan_time]
dt[,fp_t_ratio:= first_push_time/guan_time]
dt[,p_higher:=num_higher_than_sd/steps]
dt[,maxbox := max(box_completed, na.rm = T), by = num]
dt[,comp_rate:= box_completed/maxbox]
dt[,dbox:=maxbox - box_completed]
dt[,c('maxbox', 'optstep'):=NULL] # When you manipulate two variables together, 
#you have to use c() to concantenate them.
dt[,time_window := quantile(guan_time, 0.4), by = num]
dt[, suc_within := success & guan_time<=time_window]
dt[,time_window:=NULL] #setting them equal to NULL means dropping them
dt[,fail_steps:= steps - num_higher_than_sd_after]
```

':=' is a useful feature provided by data.table. It creates or updates variables based on the righthand expression. For example, the fist line means create a new variable "success" to denote whether result_flag is lower than or equal to 2.

You can inspect the data after each change in the table above.

Now we average a set of variables across each Guan by each student and whether the guan is successful or not.

```{r}
# the variable list needs to be averaged
mean_var = c("box_completed","dsteps",
             "first_move_time","first_push_time",
             "guan_time","p_optimal","rest_mean","rest_sd",
             "p_dup","f_m_ratio","fp_m_ratio","f_t_ratio",
             "fp_t_ratio","p_higher","comp_rate","dbox","num_higher_than_sd_after","fail_steps") 
# select those successful Guans, and calculate the mean of those variables by each student.
sucdt = dt[success==T, lapply(.SD, mean, na.rm = T), by  = id,.SDcols = mean_var] 
#.SD means subset of data.table. See the documentation of data.table.
# since comp_rate, dbox, box_completed are constant in successful Guans, we drop them.
```

After obtaining the mean, we transform some variables into the log form.

```{r}
lntrans = c("first_move_time","first_push_time","guan_time",
            "f_m_ratio","fp_m_ratio","f_t_ratio","fp_t_ratio")
for (var in lntrans){
  lnvar = 'ln' %s+% var # %s+% is a function from stringi package, 
  # which concatenates two strings together.
  sucdt[,(lnvar):=log(get(var))]
}
```

Then we do the same procedures to the failed Guans.

```{r}
faildt = dt[success==F, lapply(.SD, mean, na.rm = T), by  = id,.SDcols = mean_var]
lntrans = c("first_move_time","first_push_time","guan_time",
            "f_m_ratio","fp_m_ratio","f_t_ratio","fp_t_ratio")
for (var in lntrans){
  lnvar = 'ln' %s+% var 
  faildt[,(lnvar):=log(get(var))]
}
```

Then we merge these two subsets using 'id'.
```{r}
ndt = merge(sucdt, faildt, by = 'id', all.x = T, all.y = T)
```



