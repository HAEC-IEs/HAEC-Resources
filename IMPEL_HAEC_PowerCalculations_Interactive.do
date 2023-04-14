
/**********************************************************************************
 Project: 			SCUS_IDEAL_HAEC
 Title: 			Power Calculations .do File for HAEC's Request for Research Applications
 Purpose:			The purpose of this .do file is to assist applicants applying for HAEC's research grant conduct power calculations for their proposed study using Stata. 
 Version: 			Interactive V4
 Author: 			Ananda Young (ananda.young@causaldesign.com) & Rigzom Wangchuk (rigzom.wangchuk@causaldesign.com)
 Date:  			April 3, 2023
 
 *Please note that STATA version 13 or higher is needed to use the in-built power command.
 
**********************************************************************************/
	
	clear all 
	set more off
	
* STEP 0: SPECIFY FILE PATH WHERE YOU WANT TO SAVE ANY GRAPHS GENERATED FROM THIS EXERCISE
	* Create a folder in your compueter and replace the file path below with that of the folder.
	cd "" // Set directory to save graphs 

********************** 
/* 0. INTRODUCTION */
**********************
/*
 I. Intro
	This .do file will serve as a basic guide to assist you to run power calculations for your proposed study using Stata. Statistical power is the probability of correctly rejecting the null hypothesis when it's false, enabling us to understand if the project had a statistically significant effect or not. By maximizing the power of a study, we are able to minimize the likelihood that we are not able to detect an effect if the activity truly had one.
		
II. Components of Power:
	
	* Significance level (α): the probability of committing a Type I error (false negative), usually set at 5%.
	
	* Power = (1 - β): the probability of NOT committing a Type II error, usually set at 80%.
	
	* Minimum Detectable Effect (MDE) Size: The smallest program effect size that the study can detect.
	
	* Sample size (N), including cluster, strata and arm sizes if relevant: the number of units or observations that will participate in the study.
	
	* Variance (σ^2): A measure of the distribution or spread of the outcome of interest.
	
	* Treatment Allocation (P): The proportion of the sample assigned to the treatment group or arms vs. the control group (typically 50/50)
		* nratio: The nratio is the ratio of the treatment size/control size. 
			  If the value is 1, there are an equal number of people in both the treatment and control groups. 
			  If the control group size is x2 of the treatment group, the nratio is 1/2.
			  If the control group size is 1/2 of the treatment group, the nratio is 2.	
	
	* Intra-cluster Correlation Coefficiency (ICC or ρ): A measure of the relatedness of clustered data which compares the variance within a cluster with the variance between clusters. This is only a relevant parameter in clustered evaluation designs.

III. The Power Command in Stata
		
	The standard power command is as follows: 
		power [method] [group_1_mean] [group_2_mean], [power_options] [display_options] 
	
	Now, we will tailor the power command to be able to run the power calculations most relevant to our study.
	
	***Tip: Enter "help power" into Stata to learn more about all of Stata's related functions to power calculations! 
	
IV. If baseline data is available, you can pull the information (such as mean, sd, ICC, etc.) directly by loading the dataset on Stata, running the relevant commands.
	
	* To get the mean and sd of the desired variable, you can run the command: 
		sum variable_name
		
	* To get the ICC you can run the commands:
		loneway outcome cluster_id
		return list
		
		r(rho) is the ICC
*/

quietly{

* Step 1: Standard parameters 
	* Power
		noisily di in red "Power has been set to 0.8 by default."
		noisily di in red "Do you want to change the power? Enter 0 for No, 1 for Yes" _request(ans)
		gl power_q = $ans
		
		if $power_q != 1 & $power_q != 0 {														// Error code type A
			noisily di in red "ERROR: You entered a number that was not 0 or 1. Start again!"
			exit
		}
		
		if $power_q == 1 {
			noisily di in red "Enter the desired power (only values between 0 to 1):" _request(ans)
			gl power = $ans
			
		}
		else if $power_q == 0 {
			gl power = 0.8 			// Set the power at 80%
		}
		
			if $power <= 0 | $power >= 1 {														// Error code type B 
				noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
				exit 
			}
	
	* Alpha
		noisily di in red "Alpha has been set to 0.05 by default."
		noisily di in red "Do you want to change the alpha? Enter 0 for No, 1 for Yes" _request(ans)
		gl alpha_q = $ans
		
		if $alpha_q != 1 & $alpha_q != 0 {														// Error code type A
			noisily di in red "ERROR: You entered a number that was not 0 or 1. Start again!"
			exit
		}
		
		if $alpha_q == 1 {
			noisily di in green "Alpha is usually set at 0.01, 0.05, and 0.10."
			noisily di in red "Enter the desired alpha (only values between 0 to 1):" _request(ans)
			gl alpha = $ans
		}
		
		else if $alpha_q == 0 {
			gl alpha = 0.05 		// Set the confidence interval at 95% or alpha at 5% 
		}
		
			if $alpha <= 0 | $alpha >= 1 {														// Error code type B 
				noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
				exit 
			}

	
* Step 2 Test type: two-sample means or proportions test
	noisily di in red "Are you conducting a two-sample means or proportions test? Enter 1 if means; 2 if proportions " _request(ans)
	gl test = $ans
	
		if $test != 1 & $test != 2 {														// Error code type A
			noisily di in red "ERROR: You entered a number that was not 1 or 2. Start again!"
			exit
		}
	
**********************
/* TWO-SAMPLE MEANS TEST */
**********************
	if $test == 1 {
	
		* Design type: individual-level or cluster 
		noisily di in red "Is this an individual-level or cluster design? Enter 1 if individual-level; 2 if cluster " _request(ans)
		gl design = $ans
		
			if $design != 1 & $design != 2 {														// Error code type A
				noisily di in red "ERROR: You entered a number that was not 1 or 2. Start again!"
				exit
			}
**********************
/* 1. TWO-SAMPLE MEANS TEST: Design: Individual-Level Design (i.e. not cluster) */
**********************
		if $design == 1 {
			
			* Step 3: Customize parameters
			noisily di in green  "nratio: The nratio is the ratio of the treatment size/control size." ///
						_newline "If the value is 1, there are an equal number of people in both the treatment and control groups." ///
						_newline "If the control group size is x2 of the treatment group, the nratio is 1/2 or 0.5." ///
						_newline "If the control group size is 1/2 of the treatment group, the nratio is 2."
			noisily di in red "What do you want to set nratio to? Enter only positive integers or fractions" _request(ans)
			gl nratio = $ans
			
				if $nratio <= 0 {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was equal to 0 or a negative integer. Start again!"
					exit 
				}
			
			noisily di in red "Enter control mean (usually set at 100 or specify if baseline mean is known):" _request(ans)
			gl control_mean = $ans
			
			noisily di in red "Enter standard deviation (usually set at 100 or specify if baseline standard deviation is known):" _request(ans)
			gl sd = $ans 
			 		
			* Step 4: Select Method 
			noisily di in green "The difference between the control and treatment groups' means has to be the assumed MDES" ///
						_newline "You can choose to either vary MDES or sample size:" ///
						_newline "1. Vary MDES if you have expected ranges of MDES and want to know the corresponding sample sizes" ///
						_newline "2. Vary sample size if you have expected ranges of sample size and want to know the corresponding MDEs"
			noisily di in red "Do you want to vary MDES or sample size? Enter 1 if MDES; 2 if sample size " _request(ans)
			gl method = $ans
			
			if $method != 1 & $method != 2 {														// Error code type A
				noisily di in red "ERROR: You entered a number that was not 1 or 2. Start again!"
				exit
			}
			
			if $method == 1 { // Method A: Varying MDES
			
				* Step 5a: Define treatment mean
				noisily di in red "Enter lower bound of treatment mean (usually set as same as control mean so MDES = 0):" _request(ans)
				gl treat_mean_lower = $ans
				noisily di in red "Enter upper bound of treatment mean:" _request(ans)
				gl treat_mean_upper = $ans
				
					if $treat_mean_upper <= $treat_mean_lower {														// Error code type B 
						noisily di in red "ERROR: You entered a number that was equal to or smaller than the lower bound of the treatment mean. Start again!"
						exit 
					}
				
				noisily di in red "Enter MDES interval you want to graph over:" _request(ans)
				gl treat_mean_interval = $ans	
				
				if ($treat_mean_interval >= abs($control_mean - $treat_mean_upper ))  {
					
					noisily di in red "ERROR: MDES interval is equal to or more than the difference between the control mean and the upper limit of the treatment mean. Start again!" 
					exit
				}

				else if ($treat_mean_interval < abs($control_mean - $treat_mean_upper )) {
					
					* Step 6a: Graph
					noisily di in green "See where the trade-off between MDES and sample size is; and what MDES is acceptable. Here is a table and a graph:"
					noisily power twomeans $control_mean ($treat_mean_lower($treat_mean_interval)$treat_mean_upper), ///
						power($power) alpha($alpha)  nratio($nratio) sd($sd) ///
					table
					
					power twomeans $control_mean ($treat_mean_lower($treat_mean_interval)$treat_mean_upper), ///
						power($power) alpha($alpha)  nratio($nratio) sd($sd) ///
					graph(y(delta))
					
					graph export "1A_mean_MDES_samplesize.png", replace 
					
					* Step 7a: Select MDES
					noisily di in red "Enter MDES (on y-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
					gl mdes = $ans
					gl treat_mean = $control_mean + $mdes
				
					* Step 8a: Summarize the results
					power twomeans $control_mean $treat_mean, ///
						power($power) alpha($alpha) nratio($nratio) sd($sd) 
					gl samplesize = r(N)
					gl effect = r(diff)
					gl ncontrol = r(N1)
					gl ntreat = r(N2)

					di in red "The minimum sample size needed is $samplesize (treatment = $ntreat and control = $ncontrol) to detect an effect size of $effect with a probability of $power if the effect is true and the ratio of units in treatment and control is $nratio. "
} // Interval correct
} // End design = 1 & method = 1
			
			else if $method == 2 {	// Method B: Varying Sample Size
						
				* Step 5b: Define sample size
				noisily di in red "Enter lower bound of sample size (must be more than 0):" _request(ans)
				gl n_lower = $ans
				
					if $n_lower == 0 {														// Error code type B 
						noisily di in red "ERROR: You entered a number that was equal to 0. Start again!"
						exit 
					}
	
				noisily di in red "Enter upper bound of sample size" _request(ans)
				gl n_upper = $ans

					if $n_upper <= $n_lower {														// Error code type B 
						noisily di in red "ERROR: You entered a number that was equal to or smaller than the lower bound of the sample size. Start again!"
						exit 
					}
				
				noisily di in red "Enter sample size interval you want to graph over" _request(ans)
				gl n_interval = $ans
				
				if ($n_interval >= abs($n_upper - $n_lower ))  {
					
					noisily di in red "ERROR: The sample size interval is equal to or more than the difference between the lower and upper limits of the sample size. Start again!" 
					exit
				}
				
				if ($n_interval < abs($n_upper - $n_lower )) {
										
					* Step 6b: Graph
					noisily di in green "See where the trade-off between MDES and sample size is; and what sample size is acceptable. Here is a table and a graph:"
					noisily power twomeans $control_mean, n($n_lower($n_interval)$n_upper) ///
						power($power) alpha($alpha)  nratio($nratio) sd($sd) ///	
					table
					
					power twomeans $control_mean, n($n_lower($n_interval)$n_upper) ///
						power($power) alpha($alpha)  nratio($nratio) sd($sd) ///	
					graph(y(delta)) 
					
					graph export "1B_mean_MDES_samplesize.png", replace 

					* Step 7b: Based on graph from Step 6b, select sample size where efficiency gain is maximized i.e. after which the curve flattens
					noisily di in red "Enter sample size (on x-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
					gl n = $ans

					* Step 8b: Summarize the results
					power twomeans $control_mean , n($n) ///
						power($power) alpha($alpha) nratio($nratio) sd($sd) 
					gl effect = r(diff)
					gl effect = round($effect , 0.01)
					gl ncontrol = r(N1)
					gl ntreat = r(N2)

					di in red "A sample size of $n (treatment = $ntreat and control = $ncontrol) is able to detect an effect size of $effect with a probability of $power if the effect is true and the ratio of units in treatment and control is $nratio. "		
} // Interval correct
} // End design 1 & method = 2
} // End design 1 
		

**********************
/* 2. TWO-SAMPLE MEANS TEST: Design: Cluster Design */
**********************
		else if $design == 2 {	
			
			* Step 3: Customize parameters	
			noisily di in red "Enter control mean (usually set at 100):" _request(ans)
			gl control_mean = $ans
			
			noisily di in red "Enter standard deviation (usually set at 100):" _request(ans)
			gl sd = $ans 
			
			noisily di in green "The difference between the control and treatment groups' means has to be the assumed MDES" 
			noisily di in red "Enter lower bound of treatment mean (usually set as same as control mean so MDES = 0):" _request(ans)
			gl treat_mean_lower = $ans
			
			noisily di in red "Enter upper bound of treatment mean:" _request(ans)
			gl treat_mean_upper = $ans
			
				if $treat_mean_upper <= $treat_mean_lower {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was equal to or smaller than the lower bound of the treatment mean. Start again!"
					exit 
				}
			
			
			noisily di in red "Enter MDES interval you want to graph over:" _request(ans)
			gl treat_mean_interval = $ans
			
			if ($treat_mean_interval >= abs($control_mean - $treat_mean_upper ))  {
				
				noisily di in red "ERROR: MDES interval is equal to or more than the difference between the control mean and the upper limit of the treatment mean. Start again!" 
				exit
			}
			
			if ($treat_mean_interval < abs($control_mean - $treat_mean_upper )) {
				
				noisily di in green "The ICC is a measure of the relatedness of clustered data which compares the variance within a cluster with the variance between clusters." ///
					_newline "The ICC is usually set at 0.2 if baseline data is not available." ///
					_newline "If baseline data is available, see part IV. at the beginning of the code."

				noisily di in red "Enter ICC (enter value between 0 and 1):" _request(ans)
				gl icc = $ans
				
					if $icc <= 0 | $icc >= 1 {														// Error code type B 
						noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
						exit 
					}
				
				* Step 4: Select Method 		
				noisily di in green "The difference between the control and treatment groups' means has to be the assumed MDES" ///
					_newline "You can choose to either vary MDES or sample size:" ///
					_newline "1. Vary MDES and cluster size while keeping cluster number fixed. Use this method if you have expected ranges of MDEs and want to know the corresponding sample sizes." ///
					_newline "2. Vary MDES and cluster number while keeping cluster size fixed. Use this method if you have expected ranges of sample size and want to know the corresponding MDEs."
				noisily di in red "Do you want to 1. vary MDES and cluster size while keeping cluster number fixed; or 2. vary MDES and cluster number while keeping cluster size fixed? Enter 1 for the first; 2 for the second" _request(ans)
				gl method = $ans
				
				if $method != 1 & $method != 2 {														// Error code type A
					noisily di in red "ERROR: You entered a number that was not 1 or 2. Start again!"
					exit
				}
				
				if $method == 1 { // Method A: Varying MDES and cluster size; cluster number is fixed	
				
					* Step 5a: Define number of clusters
					noisily di in red "Enter number of control clusters:" _request(ans)
					gl control_cluster_num = $ans 
					noisily di in red "Enter number of treatment clusters:" _request(ans)
					gl treat_cluster_num =  $ans 
					
					* Step 6a: Graph
					noisily di in green "See where the trade-off between MDES and cluster numbers; and what MDES is acceptable. Testing different treatment lower and upper bounds, and interval maybe warranted. Here is a table and a graph:"
					
					noisily power twomeans $control_mean ($treat_mean_lower($treat_mean_interval)$treat_mean_upper), ///
						power($power) alpha($alpha) sd($sd) ///
						k1($treat_cluster_num) k2($treat_cluster_num) ///
						rho($icc) ///
					table
					
					power twomeans $control_mean ($treat_mean_lower($treat_mean_interval)$treat_mean_upper), ///
						power($power) alpha($alpha) sd($sd) ///
						k1($treat_cluster_num) k2($treat_cluster_num) ///
						rho($icc) ///
					graph(y(delta))
					
					graph export "2A_mean_MDES_clusternum.png", replace 	
					
					* Step 7a: Based on graphs from Step a, select MDES where efficiency gain is maximized i.e. after which the curve flattens
					noisily di in red "Enter MDES (on y-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
					gl mdes = $ans 	
					gl treat_mean = $control_mean + $mdes
				
					* Step 8a: Summarize the results
					power twomeans $control_mean $treat_mean, ///
							power($power) alpha($alpha) sd($sd) ///
							k1($treat_cluster_num) k2($treat_cluster_num) ///
							rho($icc) 
					gl samplesize = r(N)
					gl effect = r(diff)
					gl ncontrol = r(N1)
					gl ntreat = r(N2)
					gl controlclustsize = r(M1)
					gl treatclustsize = r(M2)

					noisily di in red "The minimum sample size needed is $samplesize (treatment = $ntreat and control = $ncontrol) to detect an effect size of $effect with a probability of $power if the effect is true. There are $control_cluster_num control clusters each of size $controlclustsize. There are $treat_cluster_num treatment clusters each of size $treatclustsize ."
					
	} // End design = 2 and method = 1
				else if $method == 2 { // Method B: Varying MDES and cluster number; cluster size is fixed
					
					* Step 5b: Define average cluster size 
					noisily di in red "Enter control cluster size:" _request(ans)
					gl control_cluster_size = $ans 
					noisily di in red "Enter treatment cluster size:" _request(ans)
					gl treat_cluster_size = $ans 
					
					* Step 6b: Graph
					noisily di in green "See where the trade-off between MDES and cluster size; and what MDES is acceptable. Testing different treatment lower and upper bounds, and interval maybe warranted. Here is a table and a graph:"
					noisily power twomeans $control_mean ($treat_mean_lower($treat_mean_interval)$treat_mean_upper), ///
						power($power) alpha($alpha) sd($sd) ///
						m1($control_cluster_size) m2($treat_cluster_size) ///
						rho($icc) ///
					table
					
					power twomeans $control_mean ($treat_mean_lower($treat_mean_interval)$treat_mean_upper), ///
						power($power) alpha($alpha) sd($sd) ///
						m1($control_cluster_size) m2($treat_cluster_size) ///
						rho($icc) ///
					graph(y(delta))
					
					graph export "2A_mean_MDES_clustersize.png", replace 	
					
					* Step 7b: Based on graphs from Step 5a, select MDES where efficiency gain is maximized i.e. after which the curve flattens\
					noisily di in red "Enter MDES (on y-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
					gl mdes = $ans 
					gl treat_mean = $control_mean + $mdes
				
					* Step 8b: Summarize the results
					power twomeans $control_mean $treat_mean, ///
								power($power) alpha($alpha) sd($sd) ///
								m1($control_cluster_size) m2($treat_cluster_size) ///
								rho($icc) 
					gl samplesize = r(N)
					gl effect = r(diff)
					gl ncontrol = r(N1)
					gl ntreat = r(N2)
					gl controlclustnum = r(K1)
					gl treatclustnum = r(K2)

					noisily di in red "The minimum sample size needed is $samplesize (treatment = $ntreat and control = $ncontrol) to detect an effect size of $effect with a probability of $power if the effect is true. There are $controlclustnum control clusters each of size $control_cluster_size. There are $treatclustnum treatment clusters each of size $treat_cluster_size ."

} // Interval correct
} // End design = 2 and method = 2
} // End design = 2
} // End test = 1	

**********************
/* TWO-SAMPLE PROPORTIONS TEST */
**********************
	else if $test == 2 { 
	
	* Design type: individual-level or cluster 
		noisily di in red "Is this an individual-level or cluster design? Enter 1 if individual-level; 2 if cluster " _request(ans)
		gl design = $ans
		
			if $design != 1 & $design != 2 {														// Error code type A
				noisily di in red "ERROR: You entered a number that was not 1 or 2. Start again!"
				exit
			}
		
**********************
/* 3. TWO-SAMPLE PROPORTIONS TEST: Design: Individual-Level Design (i.e. not cluster) */
**********************
		if $design == 1 {
			
			* Step 3: Customize parameters
			noisily di in green  "nratio: The nratio is the ratio of the treatment size/control size." ///
						_newline "If the value is 1, there are an equal number of people in both the treatment and control groups." ///
						_newline "If the control group size is x2 of the treatment group, the nratio is 1/2 or 0.5." ///
						_newline "If the control group size is 1/2 of the treatment group, the nratio is 2."
			noisily di in red "What do you want to set nratio to? Enter only positive integers or fractions" _request(ans)
			gl nratio = $ans
			
				if $nratio <= 0 {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was equal to 0 or a negative integer. Start again!"
					exit 
				}
			
			noisily di in red "Enter control proportion (enter value between 0 and 1; usually set at 0.5 or specify if baseline proportion is known):" _request(ans)
			gl control_prop = $ans
			
				if $control_prop <= 0 | $control_prop >= 1 {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
					exit 
				}
					
				* Step 4: Select Method 
				noisily di in green "The difference between the control and treatment groups' means has to be the assumed MDES" ///
							_newline "You can choose to either vary MDES or sample size:" ///
							_newline "1. Vary MDES if you have expected ranges of MDES and want to know the corresponding sample sizes" ///
							_newline "2. Vary sample size if you have expected ranges of sample size and want to know the corresponding MDEs"
				noisily di in red "Do you want to vary MDES or sample size? Enter 1 if MDES; 2 if sample size " _request(ans)
				gl method = $ans
				
				if $method != 1 & $method != 2 {														// Error code type A
					noisily di in red "ERROR: You entered a number that was not 1 or 2. Start again!"
					exit
				}
			
				if $method == 1 { // Method A: Varying MDES 
			
					* Step 5a: Define treatment proportion
					noisily di in red "Enter lower bound of treatment proportion (enter value between 0 and 1; usually set as same as control proportion so MDES = 0):" _request(ans)
					gl treat_prop_lower = $ans
					
						if $treat_prop_lower <= 0 | $treat_prop_lower >= 1 {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
							exit 
						}
		
					noisily di in red "Enter upper bound of treatment proportion (enter value between 0 and 1):" _request(ans)
					gl treat_prop_upper = $ans

						if $treat_prop_upper <= 0 | $treat_prop_upper >= 1 {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
							exit 
						}
						
						if $treat_prop_upper <= $treat_prop_lower {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was equal to or smaller than the lower bound of the treatment proportion. Start again!"
							exit 
						}						
					
					noisily di in red "Enter MDES interval you want to graph over (enter value between 0 and 1. Note that the intervals are in percentage points. So 0.01 = 1 percentage point, 0.1 = 10 percentage points, etc.):" _request(ans)
					gl treat_prop_interval = $ans
					
						if $treat_prop_interval <= 0 | $treat_prop_interval >= 1 {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
							exit 
						}
												
						if ($treat_prop_interval >= abs($control_prop - $treat_prop_upper ))  {
								noisily di in red "ERROR: MDES interval is equal to or more than the difference between the control proportion and the upper limit of the treatment proportion. Start again!" 
								exit
						}
					
					if ($treat_prop_interval < abs($control_prop - $treat_prop_upper )) {
		
						* Step 6a: Graph
						noisily di in green "See where the trade-off between MDES and sample size is; and what MDES is acceptable. Here is a table and a graph:" 
						
						noisily power twoproportions $control_prop ($treat_prop_lower($treat_prop_interval)$treat_prop_upper), ///
							power($power) alpha($alpha)  nratio($nratio) ///
						table
						
						power twoproportions $control_prop ($treat_prop_lower($treat_prop_interval)$treat_prop_upper), ///
							power($power) alpha($alpha)  nratio($nratio) ///
						graph(y(delta))
						
						graph export "3A_prop_MDES_samplesize.png", replace 	
						
						noisily di in green "Please note the MDES (y-axis) is in percentage points. So 0.01 = 1 percentage point, 0.1 = 10 percentage points, etc."
					 
						* Step 7a: Select MDES
						noisily di in red "Enter MDES (on y-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
						gl mdes = $ans
						
							if $mdes <= 0 | $mdes >= 1 {														// Error code type B 
								noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
								exit 
							}
							
						gl treat_prop = $control_prop + $mdes
					
						* Step 8a: Summarize the results
						power twoproportions $control_prop $treat_prop, ///
							power($power) alpha($alpha) nratio($nratio) 
						gl samplesize = r(N)
						gl diff = r(diff)
						gl effect = $diff * 100
						gl ncontrol = r(N1)
						gl ntreat = r(N2)

						di as error "The minimum sample size needed is $samplesize (treatment = $ntreat and control = $ncontrol) to detect an effect size of $effect percentage points percentage points with a probability of $power if the effect is true and the ratio of units in treatment and control is $nratio. "

} // Interval correct
} // End design = 1 & method = 1
	
				else if $method == 2 {	// Method B: Varying Sample Size 
						
					* Step 5b: Define sample size
					* Set realistic range for sample size
					noisily di in red "Enter lower bound of sample size (must be more than 0):" _request(ans)
					gl n_lower = $ans
					
						if $n_lower == 0 {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was equal to 0. Start again!"
							exit 
						}
		
					noisily di in red "Enter upper bound of sample size" _request(ans)
					gl n_upper = $ans
					
						if $n_upper <= $n_lower {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was equal to or smaller than the lower bound of the sample size. Start again!"
							exit 
						}
		
					noisily di in red "Enter sample size interval you want to graph over" _request(ans)
					gl n_interval = $ans
					
				if ($n_interval >= abs($n_upper - $n_lower ))  {
					
					noisily di in red "ERROR: The sample size interval is equal to or more than the difference between the lower and upper limits of the sample size. Start again!" 
					exit
				}
				
				if ($n_interval < abs($n_upper - $n_lower )) {
										
					
					* Step 6b: Graph
					noisily di in green "See where the trade-off between MDES and sample size is; and what sample size is acceptable. Here is a table and a graph:" 
					
					noisily power twoproportions $control_prop, n($n_lower($n_interval)$n_upper) ///
						power($power) alpha($alpha)  nratio($nratio) ///	
					table
					
					power twoproportions $control_prop, n($n_lower($n_interval)$n_upper) ///
						power($power) alpha($alpha)  nratio($nratio) ///	
					graph(y(delta))
					
					graph export "3B_prop_MDES_samplesize.png", replace 	

					noisily di in green "Please note the MDES (y-axis) is in percentage points. So 0.01 = 1 percentage point, 0.1 = 10 percentage points, etc."					
					* Step 7b: Based on graph from Step 6b, select sample size where efficiency gain is maximized i.e. after which the curve flattens
					noisily di in red "Enter sample size (on x-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
					gl n = $ans

					* Step 8b: Summarize the results
					power twoproportions $control_prop , n($n) ///
						power($power) alpha($alpha) nratio($nratio) 
					gl diff = r(diff)
					gl effect = $diff * 100
					gl effect = round($effect , 0.01)
					gl ncontrol = r(N1)
					gl ntreat = r(N2)

					di as error "A sample size of $n (treatment = $ntreat and control = $ncontrol) is able to detect an effect size of $effect percentage points percentage points with a probability of $power if the effect is true and the ratio of units in treatment and control is $nratio. "		

} // End design = 1 & method = 2			
} // n range correct 
} // End design = 1  


**********************
/* 4. TWO-SAMPLE PROPORTIONS TEST: Design: Cluster Design */
**********************
		else if $design == 2 {
			
			* Step 3: Customize parameters	
			noisily di in red "Enter control proportion (enter value between 0 and 1; usually set at 0.5 or specify if baseline proportion is known):" _request(ans)
			gl control_prop = $ans
			
				if $control_prop <= 0 | $control_prop >= 1 {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
					exit 
				}
			
			noisily di in red "Enter lower bound of treatment proportion (enter value between 0 and 1; usually set as same as control proportion so MDES = 0):" _request(ans)
			gl treat_prop_lower = $ans

				if $treat_prop_lower <= 0 | $treat_prop_lower >= 1 {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
					exit 
				}
		
			noisily di in red "Enter upper bound of treatment proportion (enter value between 0 and 1):" _request(ans)
			gl treat_prop_upper = $ans
			
				if $treat_prop_upper <= 0 | $treat_prop_upper >= 1 {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
					exit 
				}

				if $treat_prop_upper <= $treat_prop_lower {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was equal to or smaller than the lower bound of the treatment proportion. Start again!"
					exit 
				}
						
			noisily di in red "Enter MDES interval you want to graph over (enter value between 0 and 1. Note that the intervals are in percentage points. So 0.01 = 1 percentage point, 0.1 = 10 percentage points, etc.):" _request(ans)
			gl treat_prop_interval = $ans
			
				if $treat_prop_interval <= 0 | $treat_prop_interval >= 1 {														// Error code type B 
					noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
					exit 
				}
			
				if ($treat_prop_interval >= abs($control_prop - $treat_prop_upper ))  {
					noisily di in red "ERROR: MDES interval is equal to or more than the difference between the control proportion and the upper limit of the treatment proportion. Start again!" 
					exit
				}
			
			if ($treat_prop_interval < abs($control_prop - $treat_prop_upper )) {
			
				noisily di in green "The ICC is a measure of the relatedness of clustered data which compares the variance within a cluster with the variance between clusters." ///
					_newline "The ICC is usually set at 0.2 if baseline data is not available." ///
					_newline "If baseline data is available, see part IV. at the beginning of the code."

				noisily di in red "Enter ICC (enter value between 0 and 1):" _request(ans)
				gl icc = $ans
				
					if $icc <= 0 | $icc >= 1 {														// Error code type B 
						noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
						exit 
					}

				* Step 4: Select Method 
				noisily di in green "The difference between the control and treatment groups' means has to be the assumed MDES" ///
					_newline "You can choose to either vary MDES or sample size:" ///
					_newline "1. Vary MDES and cluster size while keeping cluster number fixed. Use this method if you have expected ranges of MDEs and want to know the corresponding sample sizes." ///
					_newline "2. Vary MDES and cluster number while keeping cluster size fixed. Use this method if you have expected ranges of sample size and want to know the corresponding MDEs."
				noisily di in red "Do you want to 1. vary MDES and cluster size while keeping cluster number fixed; or 2. vary MDES and cluster number while keeping cluster size fixed? Enter 1 for the first; 2 for the second" _request(ans)
				gl method = $ans
				
					if $method != 1 & $method != 2 {														// Error code type A
						noisily di in red "ERROR: You entered a number that was not 1 or 2. Start again!"
						exit
					}
					
				if $method == 1 { // Method A: Varying MDES and cluster size; cluster number is fixed 

					* Step 5a: Define number of clusters
					noisily di in red "Enter number of control clusters:" _request(ans)
					gl control_cluster_num = $ans 
					noisily di in red "Enter number of treatment clusters:" _request(ans)
					gl treat_cluster_num =  $ans 
					
					* Step 6a: Graph
					noisily di in green "See where the trade-off between MDES and cluster numbers; and what MDES is acceptable. Testing different treatment lower and upper bounds, and interval maybe warranted. Here is a table and a graph:"

					noisily power twoproportions $control_prop ($treat_prop_lower($treat_prop_interval)$treat_prop_upper), ///
						power($power) alpha($alpha) ///
						k1($treat_cluster_num) k2($treat_cluster_num) ///
						rho($icc) ///
					table								
					
					power twoproportions $control_prop ($treat_prop_lower($treat_prop_interval)$treat_prop_upper), ///
						power($power) alpha($alpha) ///
						k1($treat_cluster_num) k2($treat_cluster_num) ///
						rho($icc) ///
					graph(y(delta))
					
					graph export "4A_prop_MDES_clusternum.png", replace 	
					
					noisily di in green "Please note the MDES (y-axis) is in percentage points. So 0.01 = 1 percentage point, 0.1 = 10 percentage points, etc."
					* Step 7a: Based on graphs from Step 5a, select MDES where efficiency gain is maximized i.e. after which the curve flattens
					noisily di in red "Enter MDES (on y-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
					gl mdes = $ans 
					
						if $mdes <= 0 | $mdes >= 1 {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
							exit 
						}
					
					gl treat_prop = $control_prop + $mdes
				
					* Step 8a: Summarize the results
					power twoproportions $control_prop $treat_prop, ///
							power($power) alpha($alpha) ///
							k1($treat_cluster_num) k2($treat_cluster_num) ///
							rho($icc) 
					gl samplesize = r(N)
					gl diff = r(diff)
					gl effect = $diff * 100
					gl ncontrol = r(N1)
					gl ntreat = r(N2)
					gl controlclustsize = r(M1)
					gl treatclustsize = r(M2)

					noisily di in red "The minimum sample size needed is $samplesize (treatment = $ntreat and control = $ncontrol) to detect an effect size of $effect percentage points with a probability of $power if the effect is true. There are $control_cluster_num control clusters each of size $controlclustsize. There are $treat_cluster_num treatment clusters each of size $treatclustsize ."

} // End design = 2 and method = 1
				else if $method == 2 { // Method B: Varying MDES and cluster number; cluster size is fixed
					
					* Step 5b: Define average cluster size 
					noisily di in red "Enter control cluster size:" _request(ans)
					gl control_cluster_size = $ans 
					noisily di in red "Enter treatment cluster size:" _request(ans)
					gl treat_cluster_size = $ans 
					
					* Step 6b: Graph
					noisily di in green "See where the trade-off between MDES and cluster size; and what MDES is acceptable. Testing different treatment lower and upper bounds, and interval maybe warranted. Here is a table and a graph:" 
					
					noisily power twoproportions $control_prop ($treat_prop_lower($treat_prop_interval)$treat_prop_upper), ///
						power($power) alpha($alpha) ///
						m1($control_cluster_size) m2($treat_cluster_size) ///
						rho($icc) ///
					table
					
					power twoproportions $control_prop ($treat_prop_lower($treat_prop_interval)$treat_prop_upper), ///
						power($power) alpha($alpha) ///
						m1($control_cluster_size) m2($treat_cluster_size) ///
						rho($icc) ///
					graph(y(delta))
					
					graph export "4A_prop_MDES_clustersize.png", replace 	
					
					noisily di in green "Please note the MDES (y-axis) is in percentage points. So 0.01 = 1 percentage point, 0.1 = 10 percentage points, etc."									
					* Step 7b: Based on graphs from Step 5a, select MDES where efficiency gain is maximized i.e. after which the curve flattens\
					noisily di in red "Enter MDES (on y-axis) where efficiency gain is maximized i.e. after which the curve flattens:" _request(ans)
					gl mdes = $ans 	
					
						if $mdes <= 0 | $mdes >= 1 {														// Error code type B 
							noisily di in red "ERROR: You entered a number that was not between 0 to 1. Start again!"
							exit 
						}
					
					gl treat_prop = $control_prop + $mdes
				
					* Step 8b: Summarize the results
					power twoproportions $control_prop $treat_prop, ///
								power($power) alpha($alpha) ///
								m1($control_cluster_size) m2($treat_cluster_size) ///
								rho($icc) 
					gl samplesize = r(N)
					gl diff = r(diff)
					gl effect = $diff * 100
					gl ncontrol = r(N1)
					gl ntreat = r(N2)
					gl controlclustnum = r(K1)
					gl treatclustnum = r(K2)

					noisily di in red "The minimum sample size needed is $samplesize (treatment = $ntreat and control = $ncontrol) to detect an effect size of $effect percentage points with a probability of $power if the effect is true. There are $controlclustnum control clusters each of size $control_cluster_size. There are $treatclustnum treatment clusters each of size $treat_cluster_size ."
		
} // End design = 2 and method = 2

} // Interval correct
} // End design = 2	
} // End test = 2  

} // END 


**********************
/* Learning More */
**********************
	/* To learn more about the power of power calculations, check out some the following resources:
		-JPAL's "Power calculations" Research Resources (www.povertyactionlab.org/resource/power-calculations)
		-JPAL North America's "Quick Guide to Power Calculations": (www.povertyactionlab.org/resource/quick-guide-power-calculations)
		-JPAL North America's "Six Rules of Thumb for Calculating Statistical Power" (www.povertyactionlab.org/sites/default/files/research-resources/2018.03.21-Rules-of-Thumb-for-Sample-Size-and-Power_0.pdf)
		-EGAP's "10 Things To Know About Statistical Power" (egap.org/resource/10-things-to-know-about-statistical-power)
