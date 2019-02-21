#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Apr  1 18:54:11 2018

@author: Irene
"""
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn import preprocessing,metrics
from sklearn.linear_model import LassoCV
from sklearn.linear_model import Lasso
from sklearn.model_selection import KFold
from sklearn.model_selection import cross_val_score,train_test_split
from sklearn.feature_selection import RFE

os.chdir(os.pardir)
datafile = 'features_1'
dt = pd.read_csv('working_data{}{}.csv'.format(os.sep,datafile))
dt = dt.dropna(axis=0,how='any') 
dt = dt.iloc[:,0:] # pandas use .iloc to index. The first line is the number of each line added by R. 
y_1 = dt.iloc[:,1] #0=ID, 1=control_pomp, 2=glo_pomp
X_1 = dt.iloc[:,3:]
y = preprocessing.scale(y_1)
X = preprocessing.scale(X_1)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.25, random_state=4)


lasso = Lasso(random_state=4)
alphas = np.logspace(-4, 4, 50)
scores = list()
scores_std = list()
n_folds = 10

for alpha in alphas:
    lasso.alpha = alpha
    this_scores = cross_val_score(lasso, X_train, y_train, scoring='r2',cv=n_folds)
    
    scores.append(np.mean(this_scores)) 
    scores_std.append(np.std(this_scores))

scores, scores_std = np.array(scores), np.array(scores_std)

plt.figure().set_size_inches(8, 6)
plt.semilogx(alphas, scores)

# plot error lines showing +/- std. errors of the scores
std_error = scores_std / np.sqrt(n_folds)
plt.semilogx(alphas, scores + std_error, 'b--')
plt.semilogx(alphas, scores - std_error, 'b--')
# alpha=0.2 controls the translucency of the fill color
plt.fill_between(alphas, scores + std_error, scores - std_error, alpha=0.2)
plt.ylabel('CV score +/- std error')
plt.xlabel('alpha')
plt.axhline(np.max(scores), linestyle='--', color='.5')
plt.xlim([alphas[0], alphas[-1]])


lassoRegression = Lasso(alpha=0.05)
lassoRegression.fit(X_train, y_train)
print("权重向量:%s, b的值为:%.2f" % (lassoRegression.coef_, lassoRegression.intercept_))
print("损失函数的值:%.2f" % np.mean((lassoRegression.predict(X_test) - y_test) ** 2))
print("预测性能得分: %.2f" % lassoRegression.score(X_test, y_test))
#print("Linear model:", pretty_print_linear(lassoRegression.coef_))
print("r2:", metrics.r2_score(y_test, lassoRegression.fit(X_train, y_train).predict(X_test)))
print("r:",np.corrcoef(y_test, lassoRegression.fit(X_train, y_train).predict(X_test)))
print("rmse:", metrics.mean_squared_error(y_test, lassoRegression.fit(X_train, y_train).predict(X_test)))