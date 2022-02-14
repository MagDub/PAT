scenario="PA_europ";
no_logfile = false;

#scenario_type=fMRI; 
sequence_interrupt=true;
#pulse_code=1;
#pulses_per_scan=EXPARAM( "Nr_Slices" );
active_buttons = 2;
button_codes = 1,2; #1=space, which ends instructions and used to start task if fMRI trigger fails
							 #2=right, approach button in PA
							
response_matching=simple_matching;

default_background_color=255, 255, 255; 
default_text_color = 0,0,0;
default_font_size = 24;

#setting up the stimuli and trial specs
begin;  
	picture{}default;

	#Instruction screen at the start of the experiment
	text{caption = "xxx";font = "Calibri";}InstructionsText; #--> this is set based in the experiment parameters
	trial{
		trial_duration = forever;
		trial_type = specific_response;
		terminator_button = 1;
		stimulus_event{
			picture{
				text InstructionsText;
				x = 0; y = 0;
			}InstructionsPic;
			code="xxx"; #This code is set in PCL. It adds the Run Number for later analysis
		}InstructionsEvent;
	}InstructionsTrial;

	#Waiting for scanner statement
	text{caption = EXPARAM( "Wait_scanner" ); font_size = 24;font="Cambria";}Waiting;
	trial{picture{text Waiting;x=0;y=0;}Wait_pic;code="Wait_for_scanner";}Wait_for_scanner;

	#Waiting for scanner declaration for when the trigger DOES NOT WORK
	trial{trial_duration=forever;trial_type = first_response; picture{text Waiting;x=0;y=0;}Wait_pic2;code="Wait_for_scanner";target_button = 1;}Wait_for_scanner_no_trigger;

	#Elements of task trial, the four different cues
	array{
		bitmap { filename = "Shape1.bmp";}Cue_HR;
		bitmap { filename = "Shape2.bmp";}Cue_LR;
		bitmap { filename = "Shape3.bmp";}Cue_LP;
		bitmap { filename = "Shape4.bmp";}Cue_HP;
	}Cue_array;

	#Cue_trial
	trial{
		trial_type = fixed;
		trial_duration=1500;
		stimulus_event{
			picture{bitmap Cue_HR;x=0;y=0;}cue_pic;
			code="xxx";   #----> set in PCL based on presented cue
			response_active=true;
			target_button=2;
		}cue_event;
	}cue_trial;
	
	#Feedback_trial
	text{caption = "xxx"; font_size = 48;font="Calibri";}FB_text; #--> set in PCL based on feedback
	trial{
		trial_type = fixed;
		trial_duration=1500;
		stimulus_event{
			picture{
				text FB_text;
				x = 0; y = 0;
			}FBTextPic;
			code="xxx"; #--> set in PCL based on feedback
		}FB_event;
	}FB_Trial;	

	#Fixation declaration 
	text{caption = "+"; font_size = 48;font="Calibri";}Fixation;
	trial{picture{text Fixation;x=0;y=0;}Fix_pic2;code="Fix";}Fix;

	#This text is presented at the end of each run and indicates how many runs the subject still has to go and to keep still
	text {caption = "xxx"; font = "Cambria";} EndText; #--> set in PCL
	trial{
		trial_duration=5000;
		picture{
			text EndText;
			x = 0; y = 0;
		}EndTextPic;
		code="EndText";
	}EndTextTrial;	


begin_pcl;
	#######################################################################################
	# subroutines
	#######################################################################################   
	sub
		wait( int duration ) # this takes one argument of type int
	begin
		loop
			int end_time = clock.time()  + duration
			until
				clock.time() > end_time
				begin
				# do nothing
				end          
	end;

	#Get all the session specific parameters that were set at the start of the run
	int RunNr=parameter_manager.get_int("Run_Nr");
	#int TR=parameter_manager.get_int("TR");
	bool Use_Trigger=parameter_manager.get_bool("Use_Trigger");
	string Start_Instruction=parameter_manager.get_string("Start_Instruction");
	int maxRuns=parameter_manager.get_int("maxRuns");
	string Wait_scanner=parameter_manager.get_string("Wait_scanner");
	string Lose1=parameter_manager.get_string("Lose1");
	string Lose2=parameter_manager.get_string("Lose2");
	string Win1=parameter_manager.get_string("Win1");
	string Win2=parameter_manager.get_string("Win2");
	string Thank1=parameter_manager.get_string("Thank1");
	string Thank2=parameter_manager.get_string("Thank2");
	string Thank3=parameter_manager.get_string("Thank3");
	string Thank4=parameter_manager.get_string("Thank4");

	#Set the code of the instruction text. This can be used later in the excel template to 
	#determine which run was actually run. 
	InstructionsEvent.set_event_code("Instruction_Run_" + string(RunNr));
	InstructionsText.set_caption(Start_Instruction);
	InstructionsText.redraw();

	#Present instruction
	InstructionsTrial.present();

	#If the trigger works than the session will start based on the incoming pulses. Otherwise
	#the session will start when the spacebar is pressed (this should be done at the same
	#time the scanner technician presses the start button)
	#if Use_Trigger then
		#Wait_for_scanner.present();

		#int pulses = pulse_manager.main_pulse_count();

		# Wait for 1 pulses 
		#loop
			#until pulse_manager.main_pulse_count()>pulses+1
			#begin
			#end;
		
		# The fixation cross disappears after the collection of one volume. 
		#Fix.present();											

		# Wait for 4 more pulses to reach equilibrium (it says 5, but we didn't reset 
		# the pulse counter)
		#loop
			#until pulse_manager.main_pulse_count()>pulses+5
			#begin
			#end;
	#else 
		#Wait_for_scanner_no_trigger.present();
		#Fix.present();	
		#wait(TR*5);
	#end; #Use_Trigger	


	###################### start of the actual experiment
	#Fill feedback arrays (HR, LR, LP, HP)
	array <int> FB[56]={5,5,5,5,5,5,5,1,1,1,-1,-1,-5,-5,5,5,5,5,5,1,1,1,1,1,-1,-1,-5,-5,-5,-5,-5,-5,-5,-1,-1,-1,-1,-1,1,1,5,5,-5,-5,-5,-5,-5,-5,-5,-1,-1,-1,1,1,5,5}; 

	#Randomize feedback separately for HR (first 14), LR (second 14), LP (third 14), HP (fourth 14)
	FB.shuffle(1,14);
	FB.shuffle(15,28);
	FB.shuffle(29,42);
	FB.shuffle(43,56);

	#Fill fixation arrays
	array <int> Fixation1[56]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,2000,2000,2000,2000,2000,2000,2000,2000,2000,2000,2000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,4000}; 
	array <int> Fixation2[56]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,2000,2000,2000,2000,2000,2000,2000,2000,2000,2000,2000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,3000,4000}; 
	array <int> Cue_Nr[56]={1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4};

	#Randomize fixation and cue presentation
	Fixation1.shuffle();
	Fixation2.shuffle();
	Cue_Nr.shuffle();
	
	#Array which contains the names of the cue condition
	array <string> Cue_Name[4]={"Cue_HR","Cue_LR","Cue_LP","Cue_HP"};

	#these are cue counters, which track how many of a certain cue have already been presented, 
	#to be used as counters in the arrays for the feedback. 
	array <int> Cue_counter[4]={0,0,0,0};

	int Reinf_Amount=0;
	int Tot_Resp=0;

	loop int TrialNr = 1; #every session has 56 trials
		until TrialNr>56
		begin
			Tot_Resp=response_manager.total_response_count( 2 );
			
			
			#up the counter for the cue that will be presented during this trial
			Cue_counter[Cue_Nr[TrialNr]]=Cue_counter[Cue_Nr[TrialNr]]+1;

			#present the cue
			cue_pic.set_part(1, Cue_array[Cue_Nr[TrialNr]]);	
			cue_event.set_event_code(Cue_Name[Cue_Nr[TrialNr]]);
			cue_trial.present();
			
			#present fixation
			Fix.present();
			wait(Fixation1[TrialNr]); 
				
			Reinf_Amount=FB[Cue_counter[Cue_Nr[TrialNr]]+(Cue_Nr[TrialNr]-1)*14];
			#check if approach or avoid
			if response_manager.total_response_count( 2 ) > Tot_Resp then
				#subject approached, so determine feedback text based on 
				#FB
				if Reinf_Amount<0 then
					#punishment
					FB_text.set_caption(Lose1 + string(-1*Reinf_Amount) + Lose2);
				else
					# reward
					FB_text.set_caption(Win1 + string(Reinf_Amount) + Win2);
				end;
				FB_event.set_event_code("FB_" + string(Reinf_Amount));
			else
				FB_text.set_caption("+");
				FB_event.set_event_code("FB_no_" + string(Reinf_Amount));
			end;
			FB_text.redraw();

			#present feedback
			FB_Trial.present();
			
			#fixation
			Fix.present();
			wait(Fixation2[TrialNr]); 
			
			TrialNr = TrialNr + 1;

		end; #loop TrialNr

	#present end fixation
	Fix.present();
	#wait(TR*5);
			
	if RunNr<maxRuns then
		EndText.set_caption(Thank1 + string(RunNr) + Thank2 + string(maxRuns) + ".\n" + Thank3);
	elseif RunNr==maxRuns then
		EndText.set_caption(Thank4);
	end; 
	
	EndText.redraw();
	EndTextTrial.present();



