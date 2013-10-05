# Under-matching prediction: Equal Access to Quality College
[![Mesa Public School District](http://dssg.io/img/partners/mesa.png)](http://www.mpsaz.org)

Predictive models to identify high-achieving high school students who are likely to undermatch - attend 2-year rather than 4-year colleges, or not go to college at all.

This is a 2013 [Data Science for Social Good](http://www.dssg.io) project in partnership with the [Mesa Public Schools](http://www.mpsaz.org).

## The problem: college undermatching

A student's college outcome - whether a student goes to college, and the quality of that college - should depend only on their academic record. 

This is far from being a reality. Unfortunately, many socio-economic and demographic factors affect students' college outcome. [Previous studies](http://www.brookings.edu/~/media/projects/bpea/spring%202013/2013a_hoxby.pdf) have shown that high-achieving students from low-income families tend to apply to less selective colleges. 

Some students attend less selective colleges because they are more affordable, but many underprivileged students choose colleges that are both academically and financially sub-optimal. 

For example, many students in the Mesa Public School district - a large district in suburban Phoenix, Arizona - attend community colleges instead of 4 year institutions like Arizona State University (ASU). However, ASU can not only be cheaper because of financial aid, but it has a better bang for your buck because its graduation rate is much higher than that of most community colleges.

We're tackling two concrete instances of college under-matching:
* students who attend less selective colleges because of non-academic factors
* students who attend community college despite the fact that if they were to attend a four year college, they would be much more likely to graduate. 

## The solution: prediction and targeting
Our goal is to identify students at risk for college undermatching, based on their academic, demographic, socio-economic information. We use data on past high school graduates to model their college outcomes. We can then apply this predictive model on current high school students to predict their risk of under-matching, thus identifying high-risk students high schools should target with extra college counseling. 

We are working with the Mesa Public School District, the largest public school district in Arizona, to design and evaluate our predictive models.  

## Data
Here we describe the data we received from the Mesa Public School district. (We are also using data from a national nonprofit organization and other school districts in the United States.)

Mesa's data consist of anonymized records of students from Mesa, Arizona. There are four major categories of records that we use:

* Courses and grades records, which show the classes taken by a student as well as the grades they received.
* Student background information, which gives us the student's gender and ethnicity. It also tells us which high school the student attended and the census tract they reside in. 
* For additional demographic data about the student's census tract, we downloaded data from the Census Bureau's 5-year American Community Survey (ACS).
* Attendance records, which tell us how many excused and unexcused absences a student accrued in each years of high school.
* Test records, which give us the student's state standardized test scores, as well as some national ones - the PSAT, SAT, ACT, AP, and so on.

So that gives us plenty of data on historical students and how they did in high school. But that's not enough for our predictive model, we also need outcomes - in order to predict college outcomes for future students, we need to know where past students ended up.

So we also gathered college outcome data from the National Student Clearinghouse (NSC) for the students. The NSC data reports which college a student attended and college enrollment information for each semester or quarter a student remained in college. Mesa Public Schools joined the NSC data with the Mesa student records for us.

## Project layout

The repository is organized into three directories: `simulate`, `model`, `viz`, containing code responsible for generating simulation data, building models, creating visualizations respectively.

The repository also contains a directory `feature` which contains a sample of the code for feature construction. The code there cannot be ran however and plays no role in the simulation.

### Simulating data
**NOTE: Due to the sensitive nature of student-level data, we're unable to share it with the public.** 

We have, however, written scripts in the `simulate` directory to simulate data you can use to train our models.

### Data Processing
**NOTE: We're also unable to share the scripts that clean the private student-level data we received from Mesa.** 

For the sake of transparency, thought, here's a run-down of the key data processing challenges we faced:

* Transfer students. Students who transfer high schools create lots of anomalies in the data.
* Missing records. Some students have no college records, that is, no records in the NSC data. We often can't distinguish them from students who did not attend college.
* ACS data. We geocode high schools and approximately geocode students to associate them with the census tract id. We then match against the tract-level ACS data.
* Spelling mistakes. High schools and colleges often do not have a standard identification code. We have to use the school names, which are often misspelled in the data.

### Modeling
**NOTE**: The `model` directory includes models for college quality under-match, but we **cannot include our models for college graduation under-match** at this time.

We treat the problem of identifying high-risk students as a prediction problem. 

####Constructing response variables
We build a response variable that represents a student's college outcome in historical data and then either classify or regress from the student's academic, socio-economic, and demographic information.

*College quality under-match.* Constructing a response variable that represents how much better of a college a student should attend is difficult. We broke this process down into three steps: 
* First, we measure the quality of a college by the average PSAT score of the students in that college. 
* Second, we learn a model that outputs the college quality based **only on the academic profile** of the students. The output of this model represents the **target**. 
* Third, we construct the under-match variable as the difference of the target college-quality and the actual college-quality of a student. 

*College graduation under-match.* We use 2 binary response variables here: whether the student attended a four year college and whether a student graduated. From these response variables, we can estimate the probability that a student attended a four year college, and the probability that they graduated given that they attended a 4 year college - p( 4-year ) and p( grad | 4-year ).   

####Models
 We build a feature vector for each student and train the following models:

- a linear model with L1 regularization 
- a random forest 
- out-of-the-box algorithms with custom modifications

### Using our code
Starting with simulated data, you can train our models to predict the **college quality** of a student - again, not the **college graduation** - and evaluate each model using our evaluation metrics.

To do so, run the following commands:

```
python simulate/simulateStudents.py
R CMD BATCH simulate/computeColSAT.R
R CMD BATCH model/buildTarget.R
R CMD BATCH model/evaluate_models.R
R CMD BATCH viz/bargraph-plots.r
```

These scripts will simulate the data, construct the response, learn the model, evaluate errors, and produce visualization representing the errors in the `viz` directory.
