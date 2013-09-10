# Under-match Prediction: Equal Access to Quality College
This is a [Data Science for Social Good](www.dssg.io) project to identify high school students who are likely to **undermatch**, that is, students who have high academic potential but poor college outcome.

This public repository contains **a few** of the models and error metrics we used, as well as simulated data with which one can run our code. This repository contains no working data processing procedures because the actual student data are private. 

## The problems

Ideally, a student's college outcome--whether a student goes to college and the quality of a student's college--depends only on the student's academic record. 

This is however not true. Many factors, socio-economic and demographic, all affect student's college outcome. [Previous studies](http://www.brookings.edu/~/media/projects/bpea/spring%202013/2013a_hoxby.pdf) have shown that high-achieving students from low-income families tend to apply to less selective colleges. 

Some students will attend a less selective college because it is more affordable, but many underprivileged students make decisions that are both academically and financially sub-optimal. For example, many students in the Mesa Public School district attend community colleges instead of 4 year institutions like ASU. ASU can be cheaper because of financial aid and because of the fact that the graduation rate in ASU is much higher than that of a community college; ASU provides much more value for the money spent.

We tackle two concrete instances of under-match:
* students with good academic records who attend less selective colleges
* students who are likely to graduate from four year colleges but attend community colleges

## The solution: prediction and targeting
Our goal is to identify students at risk for under-match, based on their academic, demographic, socio-economic information. We use data on past high school graduates to model the students' college outcome. We can then apply the model on current high school students to predict their risk of under-matching and find the high-risk students whom the high school can provide extra counseling. 

We are working with the Mesa Public School District, the largest public school district in Arizona, to design and evaluate our predictive models. We are also using data from a national nonprofit organization and other school districts in the United States. For some demographic features, we download data from the 5-year American Communities Survey (ACS), freely available for public use. 

![Mesa Public School District](http://dssg.io/img/partners/mesa.png)

## Data

Here we describe just the data from the Mesa Public School district.
The data consist of anonymized records of students from Mesa, Arizona. There are four major categories of records that we use:

* Courses and grades records, which show the classes taken by a student as well as the grades received
* General information, which gives the student's gender and ethnicity. It also tells us which high school the student attended and the census tract in which the student resided. 
* Attendance records, which tell us how many excused and unexcused absences a student accrued in each of 4 years of high school.
* Test records, which give the state standardized test scores as well as some national ones such as the PSAT, SAT, ACT, AP, etc. 

We also use the National Student Clearinghouse (NSC) data to get the college outcome of the students. The NSC data reports which college a student attended for each semester or quarter that a student remained in college.

 Mesa Public School has joined the NSC data with the Mesa student records.

## The project

### Data Processing
NDA prevents us from sharing the data as well as the scripts with which we wrote to clean the data. Without going into details, the key data processing challenges we faced are:

* Transfer students. Students who transfer high schools create lots of anomalies in the data.
* Missing records. Some students have no college records, that is, no records in the NSC data; we often cannot distinguish them from students who did not attend college.
* ACS data. We geocode high schools and approximately geocode students to associate them with the census tract id. We then match against the ACS data.
* Spelling mistakes. High schools and colleges often do not have a standard identification code. We have to use the names, which are often misspelled in the data.


### Modeling

We treat the problem of identifying high-risk students as a prediction problem. We build a response variable that represents a student's college outcome in historical data and then either classify or regress from the student's academic, socio-economic, and demographic information. We build a feature vector for each student and train a linear model with L1 regularization as well as Random Forest to output the prediction.



