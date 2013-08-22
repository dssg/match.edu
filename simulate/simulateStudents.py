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
		"John","Juan-Pablo","Jonathan"]
all_last_names = ["Shah","Lin","Meinshausen","Eneva","Jacobs",
		"Mader","D'Agnostino","Su","Brock",
		"Gee","McFowland","Alice","Leiby",
		"Plagge","Auerbach","Vohra","Ghani","Rowe"]

all_races = ["klingon","romulan","vulcan"]

def collegeChoose(psat, gpa):
	def admitStud(stud):
		psat_l = psat-random.randint(0,80)
		psat_u = psat+random.randint(0,80)

		gpa_l = psat-random.random()*1.5
		gpa_u = psat+random.random()*1.5

		if (stud["psat"]>psat_l && stud["psat"]<psat_u &&
			stud["gpa"]>gpa_l && stud["gpa"]<gpa_u):
			return True
		return False
	return admitStud

# quality number associated with the University
all_cols_qual = {"Cranberry Lemon University":1,
		"Starfish University":2,
		"Hella Good College":3,
		"Aardvark University":4,
		"OK Community College":5,
		"Institute of Banana Harvesting":6}
all_cols_fn = {"Cranberry Lemon University":collegeChoose(240,4.0),
		"Starfish University":collegeChoose(200,3.5),
		"Hella Good College":collegeChoose(160,3.1),
		"Aardvark University":collegeChoose(120,2.5),
		"OK Community College":collegeChoose(80,2.0),
		"Institute of Banana Harvesting":collegeChoose(60,1.0)}

var_ls = ["name","sid","race","college","psat","gpa","honors"]+
	["var"+str(x) for x in range(10)]

n_stud = 1000
stud_df = DataFrame(index=range(n_stud), columns=var_ls) 

for i in range(n_stud):
	stud_df.sid[i] = i+1	
	stud_df.name[i] = random.sample(all_first_names,1)[0]+
			  random.sample(all_last_names,1)[0]
	
	stud_df.gpa[i] = random.random()*3+1
	stud_df.psat[i] = floor(random.random()*180+60)
	stud.df.honors[i] = random.randint(0,10)

	# college enrollment
		
	
