# Under-match Prediction: Equal Access to Quality College
This is a [Data Science for Social Good](www.dssg.io) project to identify high school students who are likely to **undermatch**, that is, students who have high academic potential but poor college outcome.

The data as well as most of the analysis code are not public. This repository contains a sample of some of the models we used. 

## The problems
Under-match has two facets. 

### Oh, the colleges you will go
Consider two students: Anthony and Benjamin. Anthony is poor and black; Benjamin is rich and white. [Previous studies](http://www.brookings.edu/~/media/projects/bpea/spring%202013/2013a_hoxby.pdf) have shown that even if Anthony has the same academic profile, i.e. SAT, grades, as Benjamin, Anthony is likely to attend less selective colleges.

- Anthony does not attend college
- Anthony attends a two-year college when he qualifies for a four-year college
- Anthony attends a non-selective four-year college when he qualifies for a selective one

### Higher graduation from higher education
This is a closely related problem. Students who go to community colleges are, compared to their academic equivalent peers who go to 4 year colleges, much less likely to graduate or transfer. 

## The solution: prediction and targeting
Our goal is to identify students at risk for under-match, based on their academic, demographic, socio-economic information. We use data on past high school graduates to model the students' college outcome. We can then apply the model on current high school students to predict their risk of under-matching and find the high-risk students whom the high school can provide extra counseling. 

We are working with the Mesa Public School District, the largest public school district in Arizona, to design and evaluate our predictive models. We are also using data from a national nonprofit organization and other school districts in the United States. For some demographic features, we download data from the 5-year American Communities Survey (ACS), freely available for public use. 

![Mesa Public School District](http://dssg.io/img/partners/mesa.png)

## The project

### Data Processing
NDA prevents us from sharing the data as well as the scripts with which we wrote to clean the data. Without going into details, the key data processing challenges we faced are:

* Transfer students. Students who transfer high schools create lots of anomalies in the data.
* Missing records. Some students have no college records; we often cannot distinguish them from students who did not attend college.
* ACS data. We geocode high schools and approximately geocode students to associate them with the census tract id. We then match against the ACS data.
* Spelling mistakes. High schools and colleges often do not have a standard identification code. We have to use the names, which are often misspelled in the data.


### Modeling

We treat both the problem of ... as prediction problems. We build a response variable that represents a student's college outcome in historical data and then either classify or regress from the student's academic, socio-economic, and demographic information. We build a feature vector for each student and train a linear model with L1 regularization as well as Random Forest to output the prediction.

## Data


