# Under-match Prediction: Equal Access to Quality College
This is a [Data Science for Social Good](www.dssg.io) project to identify high school students who are likely to **undermatch**, that is, students who have high academic potential but poor college outcome.

This public repository contains **a few** of the models and error metrics we used, as well as simulated data with which one can run our code. This repository contains no working data processing procedures because the actual student data are private. 

## The problems

Ideally, a student's college outcome--whether a student goes to college and the quality of a student's college--depends only on the student's academic record. 

This is however not true. Many factors, socio-economic and demographic, all affect student's college outcome. [Previous studies](http://www.brookings.edu/~/media/projects/bpea/spring%202013/2013a_hoxby.pdf) have shown that high-achieving students from low-income families tend to apply to less selective colleges. 

Some students will attend a less selective college because it is more affordable, but many underprivileged students make decisions that are both academically and financially sub-optimal. For example, many students in the Mesa Public School district attend community colleges instead of 4 year institutions like ASU. ASU can be cheaper because of financial aid and because of the fact that the graduation rate in ASU is much higher than that of a community college; ASU provides much more value for the money spent.

We tackle two concrete instances of under-match:
* students who attend less selective colleges because of non-academic factors
* students who attend community college despite the fact that if they were to attend a four year college, they would be much more likely to graduate. 

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

We also use the National Student Clearinghouse (NSC) data to get the college outcome of the students. The NSC data reports which college a student attended and certain various college enrollment information for each semester or quarter that a student remained in college.

 Mesa Public School has joined the NSC data with the Mesa student records.

## The project

### Data Processing
NDA prevents us from sharing the data as well as the scripts with which we wrote to clean the data. Without going into details, the key data processing challenges we faced are:

* Transfer students. Students who transfer high schools create lots of anomalies in the data.
* Missing records. Some students have no college records, that is, no records in the NSC data; we often cannot distinguish them from students who did not attend college.
* ACS data. We geocode high schools and approximately geocode students to associate them with the census tract id. We then match against the ACS data.
* Spelling mistakes. High schools and colleges often do not have a standard identification code. We have to use the names, which are often misspelled in the data.


### Modeling

We treat the problem of identifying high-risk students as a prediction problem. We build a response variable that represents a student's college outcome in historical data and then either classify or regress from the student's academic, socio-economic, and demographic information. We build a feature vector for each student and train a linear model with L1 regularization as well as Random Forest to output the prediction. We also tried custom modifications to out-of-the-box algorithms.

**College quality under-match.** It is a complex process to construct a response variable that represents how much better of a college a student should attend. We break down the construction into three steps: 
* First, we measure the quality of a college by the average PSAT score of the students in that college. 
* Second, we learn a model that outputs the college quality based **only on the academic profile** of the students. The output of this model represents the **target**. 
* Third, we construct the under-match variable as the difference of the target college-quality and the actual college-quality of a student. 

**College graduation under-match.** We use 2 binary response variables here: whether the student attended a four year college and whether a student graduated. From these response variables, we can estimate the probability p( grad | 4year ) as well as p( 4year ).   


## Simulation

We provide a basic simulation that demonstrates how we predict the college quality of a student as well as the evaluation metrics we use. We **do not** include code that models a student's graduation probabilities. 

```
python simulate/simulateStudents.py
R CMD BATCH simulate/computeColSAT.R
R CMD BATCH model/buildTarget.R
R CMD BATCH model/evaluate_models.R
R CMD BATCH viz/bargraph-plots.r
```

The above commands will simulate the data, construct the response, learn the model, evaluate errors, and produce visualization representing the errors in the `viz` directory.

The repository is organized into three directories: `simulate`, `model`, `viz`, containing code responsible for generating simulation data, building models, creating visualizations respectively.

The repository also contains a directory `feature` which contains a sample of the code for feature construction. The code there cannot be ran however and plays no role in the simulation.
