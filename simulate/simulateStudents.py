'''
Simulates the data used in the under-match analysis

Outputs a table named "students"
with fields:
 "name","sid","race","college","psat","gpa","honors",
 "var1","var2",..."var10" other features (nonpredictive here)
	for students, more academic, economic, 
	demographics, etc.

'''

import numpy as np
import pandas as pd
import random

# random names
all_first_names = ["Allen","Andrea","Edward","Tom","Michelangelo",
		"Nick","Nihar","Elena","Chris","Zahra",
		"Varoon","Sam","Kayla","Paul","Sophia",
		"John","Juan-Pablo","Jonathan","Nathan","Vidhur",
		"Matt","Rayid"]
all_last_names = ["Shah","Lin","Meinshausen","Eneva","Jacobs",
		"Mader","D'Agnostino","Su","Brock",
		"Gee","McFowland","Alice","Leiby",
		"Plagge","Auerbach","Vohra","Ghani","Rowe","Velez",
		"Brown","Ashktorab","Bashyakarla","Adhikari"]

all_races = ["klingon","romulan","vulcan","cardassian"]

def collegeChoose(psat, gpa):
	def admitStud(stud):
		psat_l = psat-random.randint(0,80)
		psat_u = psat+random.randint(0,80)

		gpa_l = gpa-random.random()*1.5
		gpa_u = gpa+random.random()*1.5

		return (stud["psat"]>psat_l and stud["psat"]<psat_u and \
			stud["gpa"]>gpa_l and stud["gpa"]<gpa_u)
	return admitStud

# quality number associated with the University
all_cols_id = {"Cranberry Lemon University":1,
		"Starfish University":2,
		"Whale University":3,
		"Aardvark University":4,
		"Cappybara Community College":5,
		"Mount Yo-yo College":6,
		"Institute of Banana Harvesting":7}

all_cols_fn = {"Cranberry Lemon University":collegeChoose(240,4.0),
		"Starfish University":collegeChoose(200,3.5),
		"Whale University":collegeChoose(170,3.1),
		"Aardvark University":collegeChoose(140,2.5),
		"Cappybara Community College":collegeChoose(110,2.0),
		"Mount Yo-yo College":collegeChoose(80,1.5),
		"Institute of Banana Harvesting":collegeChoose(60,1.0)}

var_ls = ["name","sid","race","college","psat","gpa","honors"]
var_ls.extend(["var"+str(x) for x in range(10)])

n_stud = 1000
stud_df = pd.DataFrame(index=range(n_stud), columns=var_ls) 

for i in range(n_stud):
	stud_df.sid[i] = i+1	
	stud_df.name[i] = random.sample(all_first_names,1)[0] + " " + \
			  random.sample(all_last_names,1)[0]
	stud_df.race[i] = random.sample(all_races, 1)[0]
	stud_df.gpa[i] = random.random()*3+1
	stud_df.psat[i] = max(min(np.floor(stud_df.gpa[i]*60 + \
				(0.5-random.random())*120),
				240), 60)
	stud_df.honors[i] = random.randint(0,10)
	
	# college enrollment
	admitted = [mykey for mykey in all_cols_fn \
			if all_cols_fn[mykey](stud_df.iloc[i])]
	if len(admitted) == 0:
		stud_df.college[i] = "Institute of Banana Harvesting"
	else :
		stud_df.college[i] = random.sample(admitted,1)[0] 

	
stud_df.to_csv("../students.csv")


