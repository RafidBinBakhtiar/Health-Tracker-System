; =======================
; HEALTH PREDICT+ (Merged)
; Menu:
;  1. SugarPressure Insight (BS + BP)
;  2. OxyUric Analyzer (SpO2 + Uric)
;  3. BMI Calculator
;  4. Caloric Calculator (BMR)
;  5. Overall Health Risk Assessment
;  6. Diet Chart Generator
;  7. Exit
; Notes:
;  - Overall Risk keeps NO XOR/SHL (simple adds/comps only).
;  - BMR + Diet from Rafid integrated; BMR updates last_calories/have_cal.
; =======================

.MODEL SMALL
.STACK 200h

.DATA
    height_conversion_warning db 'Warning: Precise height conversion may be approximate$'
    MENU_MSG DB '*** HEALTH PREDICT+ ***$'
    MENU_1   DB '1. SugarPressure Insight$'
    MENU_2   DB '2. OxyUric Analyzer$'
    MENU_3   DB '3. BMI Calculator$'
    MENU_4   DB '4. Caloric Calculator (BMR)$'
    MENU_5   DB '5. Overall Health Risk Assessment$'
    MENU_6   DB '6. Diet Chart Generator$'
    MENU_7   DB '7. Exit$'
    CHOICE_MSG DB 'Enter your choice (1-7): $'

    MSG1 DB 'Enter Blood Sugar (mg/dL) in 2 digits: $'
    MSG2 DB 'Enter Systolic BP (mmHg) digits choice [2 for 2 digits/3 for 3 digits]: $'
    MSG3 DB 'Enter Systolic BP (mmHg): $'
    MSG4 DB 'Enter Diastolic BP (mmHg) in 2 digits: $'
    MSG5 DB 'Enter Oxygen Saturation (%) in 2 digits: $'
    MSG6 DB 'Enter Uric Acid (mg/dL) in 1 digit: $'

    NEWLINE DB 0DH,0AH,'$'
    SPACE   DB '  $'

    SUGAR     DW ?
    SYSTOLIC  DW ?
    DIASTOLIC DW ?
    OXYGEN    DW ?
    URIC      DB ?
    CHOICE    DB ?

    HEADER DB 'Medical History  |Value| Normal|           Diagnosis                         |$'
    LINE   DB '--------------------------------------------------------------------------------$'

    PARAM1 DB 'Blood Sugar(mg/dL)  $'
    PARAM2 DB 'Systolic BP(mmHg)  $'
    PARAM3 DB 'Diastolic BP(mmHg)  $'
    PARAM4 DB 'Oxygen Sat(%)       $'
    PARAM5 DB 'Uric Acid(mg/dL)     $'

    RANGE1 DB '70-90  $'
    RANGE2 DB '90-120 $'
    RANGE3 DB '60-80  $'
    RANGE4 DB '95-100 $'
    RANGE5 DB '3-7    $'

    NORMAL_MSG_BS DB 'Your Blood Sugar level is normal$'
    HIGH_MSG_BS   DB 'You are likely to be diabetic.  Consult Specialist$'
    LOW_MSG_BS    DB 'Your blood sugar level is low. Consult Specialist$'

    NORMAL_MSG_BP DB 'Your Blood Pressure is normal$'
    HIGH_MSG_BP   DB 'You have High Pressure.  Consult Specialist$'
    LOW_MSG_BP    DB 'You have Low Pressure.  Consult Specialist$'

    NORMAL_MSG_OS DB 'Your Oxygen Saturation is normal$'
    HIGH_MSG_OS   DB 'Your O2 Saturation is abnormal.  Consult Specialist$'
    LOW_MSG_OS    DB 'Your O2 Saturation is low.  Consult Specialist$'

    NORMAL_MSG_UA DB 'Your Uric Acid Level is normal$'
    HIGH_MSG_UA   DB 'You have Hyperuricemia.  Consult Specialist$'
    LOW_MSG_UA    DB 'You have Fanconi syndrome.  Consult Specialist$'

    PROMPT_HEIGHT DB 'Enter height (1 for cm, 2 for inch): $'
    PROMPT_CM     DB 'Enter height in cm (3 digits): $'
    PROMPT_INCH   DB 'Enter height in inches (2 digits): $'
    PROMPT_WEIGHT DB 'Enter weight (1 for kg, 2 for lb): $'
    PROMPT_KG     DB 'Enter weight in kg (2 digits): $'
    PROMPT_LB     DB 'Enter weight in lb (3 digits): $'
    BMI_MSG       DB 'Your BMI is: $'

    HEIGHT   DW ?
    WEIGHT   DW ?
    BMI      DW ?       ; BMI*10 (one decimal)
    statusLow    db 'Remarks: You have low Weight. Try eating something.$'
    statusNormal db 'Remarks: You have normal Weight. You are absolutely perfect.$'
    statusHigh   db 'Remarks: You are overweight. Try eating salad for once and maintain diet.$'
    temporary db ?

    ; ===== Shared “latest values” for Overall Risk =====
    last_sugar    dw 0
    last_sys      dw 0
    last_dia      dw 0
    last_spo2     dw 0
    last_uric     db 0
    last_bmi10    dw 0
    last_calories dw 0

    have_sugar db 0
    have_bp    db 0
    have_spo2  db 0
    have_uric  db 0
    have_bmi   db 0
    have_cal   db 0

    ; ===== Overall Risk strings and tables =====
    RISK_TITLE   db '*** OVERALL HEALTH RISK ***$'
    MISSING_DATA db 'Some inputs missing. Please run required modules first.$'
    RISK_OUT     db 'Overall risk level: $'
    RISK_TIP     db 'Lifestyle tip: $'
    RISK_LOW     db 'LOW$'
    RISK_MED     db 'MEDIUM$'
    RISK_HIGH    db 'HIGH$'
    TIP_LOW      db 'Keep it up: balanced diet + regular walk.$'
    TIP_MED      db 'Control sugar/salt, 150 min/wk exercise, recheck in 1 month.$'
    TIP_HIGH     db 'Consult a specialist, adopt strict diet, monitor weekly.$'

    RISK_LABELS  DW OFFSET RISK_LOW, OFFSET RISK_MED, OFFSET RISK_HIGH
    TIP_TABLE    DW OFFSET TIP_LOW,  OFFSET TIP_MED, OFFSET TIP_HIGH

    ; ===== Rafid (BMR + Diet) =====
    ; Prompts (reuse prompt_age from your code; add gender prompt)
    prompt_age    db 'Enter age in years (2 digits): $'
    prompt_gender db 'Enter gender (M/F): $'

    ; Outputs / diet labels
    result_msg    db 'Your Basal Metabolic Rate (BMR): $'
    CAL_SUFFIX    db ' calories$'
    SPACE2        db '  $'
    diet_header   db 0Dh,0Ah,'*** PERSONALIZED DIET CHART (BMR-based) ***',0Dh,0Ah,'$'
    diet_line     db '-----------------------------------------------',0Dh,0Ah,'$'
    range_label   db 'Matched Range: $'
    consult_msg   db 'Outside supported range. Consult a nutritionist.$'
    veg_label     db 'Vegetables (1/4): $'
    pro_label     db 'Proteins   (2/4): $'
    fat_label     db 'Fats       (1/4): $'
    tips_msg      db 0Dh,0Ah,'Nutrition Tips:',0Dh,0Ah,'$'
    tip1          db '- Drink 8-10 glasses of water daily',0Dh,0Ah,'$'
    tip2          db '- Include protein in every meal',0Dh,0Ah,'$'
    tip3          db '- Eat vegetables with every meal',0Dh,0Ah,'$'
    tip4          db '- Avoid processed foods',0Dh,0Ah,'$'
    tip5          db '- Get adequate sleep for metabolism',0Dh,0Ah,'$'

    ; State for BMR + Diet
    age      DW 0
    gender   DB 0
    bmr      DW 0
    veg_cals DW 0
    pro_cals DW 0
    fat_cals DW 0
    range_str DB '0000-0000$',0
    valid_range DB 0

    ; Random food tables
    veg_tab  DW OFFSET veg1, OFFSET veg2, OFFSET veg3, OFFSET veg4, OFFSET veg5
    veg1     DB 'Fulkopi$',0
    veg2     DB 'Pui Shag$',0
    veg3     DB 'Misty Kumra $',0
    veg4     DB 'Dharosh$',0
    veg5     DB 'Gajor$',0

    pro_tab  DW OFFSET pro1, OFFSET pro2, OFFSET pro3, OFFSET pro4, OFFSET pro5
    pro1     DB 'Chicken$',0
    pro2     DB 'Fish Curry$',0
    pro3     DB 'Badam$',0
    pro4     DB 'Tok Doi$',0
    pro5     DB 'Lentils$',0

    fat_tab  DW OFFSET fat1, OFFSET fat2, OFFSET fat3, OFFSET fat4, OFFSET fat5
    fat1     DB 'Avocado$',0
    fat2     DB 'Khati Shorishar Tel$',0
    fat3     DB 'Kaju Badam$',0
    fat4     DB 'Makhon$',0
    fat5     DB 'Ponir$',0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX           ; needed for diet range string builder

MENU:
    LEA DX, MENU_MSG
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MENU_1
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MENU_2
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MENU_3
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MENU_4
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MENU_5
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MENU_6
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MENU_7
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, CHOICE_MSG
    MOV AH, 9
    INT 21H

    MOV AH, 1
    INT 21H
    SUB AL, '0'

    CMP AL, 1
    JE VITAL_SIGNS          ; 1: SugarPressure
    CMP AL, 2
    JE DualVital_Check      ; 2: OxyUric
    CMP AL, 3
    JE BMI_CALC
    CMP AL, 4
    JE BMR_CALC             ; 4: BMR (Rafid)
    CMP AL, 5
    JE OVERALL_RISK
    CMP AL, 6
    JE DIET_GENERATOR       ; 6: Diet (Rafid)
    CMP AL, 7
    JE EXIT_PROGRAM
    JMP MENU

; =================== 1) SUGAR + BP ===================
VITAL_SIGNS:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Blood Sugar
    LEA DX, MSG1
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    MOV SUGAR, AX
    MOV last_sugar, AX
    MOV have_sugar, 1

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Systolic choice
    LEA DX, MSG2
    MOV AH, 9
    INT 21H
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    MOV CHOICE, AL

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, MSG3
    MOV AH, 9
    INT 21H

    CMP CHOICE, 2
    JE TWO_DIGITS_INPUT
    CMP CHOICE, 3
    JE THREE_DIGITS_INPUT
    JMP TWO_DIGITS_INPUT

TWO_DIGITS_INPUT:
    CALL READ_TWO_DIGITS
    MOV SYSTOLIC, AX
    JMP CONTINUE_INPUT

THREE_DIGITS_INPUT:
    CALL READ_THREE_DIGITS
    MOV SYSTOLIC, AX

CONTINUE_INPUT:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Diastolic
    LEA DX, MSG4
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    MOV DIASTOLIC, AX

    MOV AX, SYSTOLIC
    MOV last_sys, AX
    MOV AX, DIASTOLIC
    MOV last_dia, AX
    MOV have_bp, 1

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    CALL DISPLAY_RESULTS1

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    JMP MENU

; =================== 2) OXYGEN + URIC ===================
DualVital_Check:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Oxygen
    LEA DX, MSG5
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    MOV OXYGEN, AX
    MOV last_spo2, AX
    MOV have_spo2, 1

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Uric Acid (1 digit)
    LEA DX, MSG6
    MOV AH, 9
    INT 21H
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    MOV URIC, AL
    MOV last_uric, AL
    MOV have_uric, 1

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    CALL DISPLAY_RESULTS2

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    JMP MENU

; =================== 3) BMI CALCULATOR ===================
BMI_CALC:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, PROMPT_HEIGHT
    MOV AH, 9
    INT 21H

    MOV AH, 1
    INT 21H
    SUB AL, '0'

    CMP AL, 1
    JE CM_INPUT
    JMP INCH_INPUT

CM_INPUT:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    LEA DX, PROMPT_CM
    MOV AH, 9
    INT 21H
    CALL READ_THREE_DIGITS
    MOV HEIGHT, AX
    JMP WEIGHT_INPUT

INCH_INPUT:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    LEA DX, PROMPT_INCH
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    MOV BX, 254
    MUL BX
    MOV BX, 100
    DIV BX
    MOV HEIGHT, AX

WEIGHT_INPUT:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    LEA DX, PROMPT_WEIGHT
    MOV AH, 9
    INT 21H
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    CMP AL, 1
    JE KG_INPUT
    JMP LB_INPUT

KG_INPUT:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    LEA DX, PROMPT_KG
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    MOV BX, 100
    MUL BX
    MOV WEIGHT, AX
    JMP CALCULATE_BMI

LB_INPUT:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    LEA DX, PROMPT_LB
    MOV AH, 9
    INT 21H
    CALL READ_THREE_DIGITS
    MOV BX, 45
    MUL BX
    MOV BX, 100
    DIV BX
    MOV BX, 100
    MUL BX
    MOV WEIGHT, AX

CALCULATE_BMI:
    ; BMI*10 = (WEIGHT(kg*100) * 1000) / (HEIGHT(cm)^2)
    MOV AX, HEIGHT
    MOV BX, HEIGHT
    MUL BX
    MOV BX, 100
    DIV BX
    MOV BX, AX

    MOV AX, WEIGHT
    MOV DX, 0
    DIV BX
    MOV BX, 10
    MUL BX
    MOV BMI, AX

    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    LEA DX, BMI_MSG
    MOV AH, 9
    INT 21H

    MOV AX, BMI
    CALL DISPLAY_NUM
    CALL CheckBMIStatus

    ; Save for risk
    MOV AX, BMI
    MOV last_bmi10, AX
    MOV have_bmi, 1

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    JMP MENU

; =================== 4) BMR CALCULATOR (Rafid) ===================
BMR_CALC:
    ; newline
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; Age
    LEA DX, prompt_age
    MOV AH, 9
    INT 21h
    CALL READ_TWO_DIGITS
    CMP AX, 10
    JB  BMR_AGE_DEF
    CMP AX, 120
    JA  BMR_AGE_DEF
    JMP BMR_AGE_OK
BMR_AGE_DEF: MOV AX, 25
BMR_AGE_OK:  MOV age, AX

    ; newline
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; Gender
    LEA DX, prompt_gender
    MOV AH, 9
    INT 21h
    MOV AH, 1
    INT 21h
    MOV gender, AL

    ; newline
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; Height unit
    LEA DX, PROMPT_HEIGHT
    MOV AH, 9
    INT 21h
    MOV AH, 1
    INT 21h
    SUB AL, '0'
    CMP AL, 1
    JE  BMR_H_CM
    JMP BMR_H_IN

BMR_H_CM:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    LEA DX, PROMPT_CM
    MOV AH, 9
    INT 21h
    CALL READ_THREE_DIGITS
    CMP AX, 100
    JB  BMR_H_DEF
    CMP AX, 250
    JA  BMR_H_DEF
    JMP BMR_H_STORE
BMR_H_DEF:   MOV AX, 170
BMR_H_STORE: MOV HEIGHT, AX
    JMP BMR_W_CHOOSE

BMR_H_IN:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    LEA DX, PROMPT_INCH
    MOV AH, 9
    INT 21h
    CALL READ_TWO_DIGITS
    CMP AX, 48
    JB  BMR_H_DEF
    CMP AX, 84
    JA  BMR_H_DEF
    MOV BX, 254
    MUL BX
    MOV BX, 100
    DIV BX
    MOV HEIGHT, AX

BMR_W_CHOOSE:
    ; Weight
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    LEA DX, PROMPT_WEIGHT
    MOV AH, 9
    INT 21h
    MOV AH, 1
    INT 21h
    SUB AL, '0'
    CMP AL, 1
    JE  BMR_W_KG
    JMP BMR_W_LB

BMR_W_KG:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    LEA DX, PROMPT_KG
    MOV AH, 9
    INT 21h
    CALL READ_TWO_DIGITS
    CMP AX, 30
    JB  BMR_W_DEF
    CMP AX, 200
    JA  BMR_W_DEF
    JMP BMR_W_STORE
BMR_W_DEF:   MOV AX, 70
BMR_W_STORE: MOV WEIGHT, AX
    JMP BMR_COMPUTE

BMR_W_LB:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    LEA DX, PROMPT_LB
    MOV AH, 9
    INT 21h
    CALL READ_THREE_DIGITS
    CMP AX, 66
    JB  BMR_W_DEF
    CMP AX, 440
    JA  BMR_W_DEF
    MOV BX, 45
    MUL BX
    MOV BX, 100
    DIV BX
    MOV WEIGHT, AX

BMR_COMPUTE:
    CALL CALCULATE_BMR

    ; print BMR
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    LEA DX, result_msg
    MOV AH, 9
    INT 21h
    MOV AX, bmr
    CALL PRINT_NUM
    LEA DX, CAL_SUFFIX
    MOV AH, 9
    INT 21h

    ; Save BMR into Overall Risk calories
    MOV AX, bmr
    MOV last_calories, AX
    MOV have_cal, 1

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    JMP MENU

; =================== 5) OVERALL HEALTH RISK ===================
OVERALL_RISK:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    LEA DX, RISK_TITLE
    MOV AH, 9
    INT 21h
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; need at least sugar + bp + bmi
    MOV BL, have_sugar
    CMP BL, 0
    JE  risk_missing
    MOV BL, have_bp
    CMP BL, 0
    JE  risk_missing
    MOV BL, have_bmi
    CMP BL, 0
    JE  risk_missing
    JMP risk_continue

risk_missing:
    LEA DX, MISSING_DATA
    MOV AH, 9
    INT 21h
    JMP risk_exit

risk_continue:
    MOV SI, 0

    ; sugar
    PUSH last_sugar
    CALL ASSESS_SUGAR
    CMP  AL, 0
    JNE  rs_sug_notlow
    SUB  SI, 1
    JMP  rs_sug_done
rs_sug_notlow:
    CMP  AL, 2
    JNE  rs_sug_done
    ADD  SI, 2
rs_sug_done:

    ; bp
    PUSH last_dia
    PUSH last_sys
    CALL ASSESS_BP
    CMP  AL, 0
    JNE  rs_bp_notlow
    ADD  SI, 1
    JMP  rs_bp_done
rs_bp_notlow:
    CMP  AL, 2
    JNE  rs_bp_done
    ADD  SI, 2
rs_bp_done:

    ; spo2 (optional)
    MOV BL, have_spo2
    CMP BL, 0
    JE  rs_spo2_skip
    MOV AX, last_spo2
    CMP AX, 95
    JL  rs_spo2_low
    CMP AX, 100
    JLE rs_spo2_ok
    ADD SI, 1
    JMP rs_spo2_done
rs_spo2_low:
    ADD SI, 2
    JMP rs_spo2_done
rs_spo2_ok:
rs_spo2_done:
rs_spo2_skip:

    ; uric (optional)
    MOV BL, have_uric
    CMP BL, 0
    JE  rs_uric_skip
    MOV AL, last_uric
    MOV AH, 0
    CMP AX, 3
    JL  rs_uric_low
    CMP AX, 7
    JG  rs_uric_high
    JMP rs_uric_done
rs_uric_low:
    ADD SI, 1
    JMP rs_uric_done
rs_uric_high:
    ADD SI, 2
rs_uric_done:
rs_uric_skip:

    ; bmi (present)
    MOV AX, last_bmi10
    CMP AX, 185
    JL  rs_bmi_low
    CMP AX, 250
    JLE rs_bmi_ok
    ADD SI, 2
    JMP rs_bmi_done
rs_bmi_low:
    ADD SI, 1
    JMP rs_bmi_done
rs_bmi_ok:
rs_bmi_done:

    ; calories (optional mild)
    MOV BL, have_cal
    CMP BL, 0
    JE  rs_cal_skip
    MOV AX, last_calories
    CMP AX, 1200
    JL  rs_cal_bad
    CMP AX, 3500
    JG  rs_cal_bad
    JMP rs_cal_done
rs_cal_bad:
    ADD SI, 1
rs_cal_done:
rs_cal_skip:

    ; score -> AL (0/1/2)
    MOV AX, SI
    CMP AX, 2
    JL  risk_cat_low
    CMP AX, 4
    JL  risk_cat_med
    MOV AL, 2
    JMP risk_store
risk_cat_low:
    MOV AL, 0
    JMP risk_store
risk_cat_med:
    MOV AL, 1

risk_store:
    MOV temporary, AL

risk_print:
    LEA DX, RISK_OUT
    MOV AH, 9
    INT 21h

    MOV AL, temporary
    MOV BH, 0
    MOV BL, AL
    ADD BX, BX
    MOV SI, OFFSET RISK_LABELS
    ADD SI, BX
    MOV DX, [SI]
    MOV AH, 9
    INT 21h

    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    LEA DX, RISK_TIP
    MOV AH, 9
    INT 21h

    MOV AL, temporary
    MOV BH, 0
    MOV BL, AL
    ADD BX, BX
    MOV SI, OFFSET TIP_TABLE
    ADD SI, BX
    MOV DX, [SI]
    MOV AH, 9
    INT 21h

risk_exit:
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    JMP MENU

; =================== 6) DIET CHART GENERATOR (Rafid) ===================
DIET_GENERATOR:
    ; newline
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; Check ranges for current bmr
    CALL CHECK_RANGES
    CMP valid_range, 1
    JNE DIET_CONSULT

    LEA DX, diet_header
    MOV AH, 9
    INT 21h
    LEA DX, diet_line
    MOV AH, 9
    INT 21h

    LEA DX, range_label
    MOV AH, 9
    INT 21h
    LEA DX, range_str
    MOV AH, 9
    INT 21h
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    CALL CALCULATE_MACROS_BMR

    ; Vegetables
    LEA DX, veg_label
    MOV AH, 9
    INT 21h
    MOV AX, veg_cals
    CALL PRINT_NUM
    LEA DX, CAL_SUFFIX
    MOV AH, 9
    INT 21h
    LEA DX, SPACE2
    MOV AH, 9
    INT 21h
    CALL PRINT_RANDOM_VEG
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; Proteins
    LEA DX, pro_label
    MOV AH, 9
    INT 21h
    MOV AX, pro_cals
    CALL PRINT_NUM
    LEA DX, CAL_SUFFIX
    MOV AH, 9
    INT 21h
    LEA DX, SPACE2
    MOV AH, 9
    INT 21h
    CALL PRINT_RANDOM_PRO
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; Fats
    LEA DX, fat_label
    MOV AH, 9
    INT 21h
    MOV AX, fat_cals
    CALL PRINT_NUM
    LEA DX, CAL_SUFFIX
    MOV AH, 9
    INT 21h
    LEA DX, SPACE2
    MOV AH, 9
    INT 21h
    CALL PRINT_RANDOM_FAT
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX

    ; Tips
    LEA DX, tips_msg
    MOV AH, 9
    INT 21h
    LEA DX, tip1
    MOV AH, 9
    INT 21h
    LEA DX, tip2
    MOV AH, 9
    INT 21h
    LEA DX, tip3
    MOV AH, 9
    INT 21h
    LEA DX, tip4
    MOV AH, 9
    INT 21h
    LEA DX, tip5
    MOV AH, 9
    INT 21h

    JMP MENU

DIET_CONSULT:
    LEA DX, consult_msg
    MOV AH, 9
    INT 21h
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21h
    POP DX
    JMP MENU

; =================== EXIT ===================
EXIT_PROGRAM:
    MOV AH, 4CH
    INT 21H
MAIN ENDP

; =================== PROCEDURES ===================

; --- Readers/printing (from your code) ---
READ_TWO_DIGITS PROC
    PUSH BX
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    MOV BL, AL
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    MOV BH, 0
    MOV AH, 0
    PUSH AX
    MOV AL, BL
    MOV BL, 10
    MUL BL
    POP BX
    ADD AL, BL
    MOV AH, 0
    POP BX
    RET
READ_TWO_DIGITS ENDP

READ_THREE_DIGITS PROC
    PUSH BX
    PUSH CX
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    MOV BL, AL
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    MOV CL, AL
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    PUSH AX
    MOV AL, BL
    MOV BL, 100
    MUL BL
    MOV BX, AX
    MOV AL, CL
    MOV CL, 10
    MUL CL
    ADD BX, AX
    POP AX
    AND AX, 00FFH
    ADD AX, BX
    POP CX
    POP BX
    RET
READ_THREE_DIGITS ENDP

PRINT_NUM PROC
    MOV CX, 0
    MOV BX, 10
pn_div:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE pn_div
pn_out:
    POP DX
    ADD DL, '0'
    MOV AH, 2
    INT 21H
    LOOP pn_out
    RET
PRINT_NUM ENDP

; -------- Display tables (split) --------
DISPLAY_RESULTS1 PROC
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    LEA DX, HEADER
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    LEA DX, LINE
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Blood Sugar Row
    LEA DX, PARAM1
    MOV AH, 9
    INT 21H
    MOV AX, SUGAR
    CALL PRINT_NUM
    LEA DX, SPACE
    MOV AH, 9
    INT 21H
    LEA DX, RANGE1
    MOV AH, 9
    INT 21H
    MOV AX, SUGAR
    CMP AX, 70
    JL SUGAR_LOW
    CMP AX, 90
    JG SUGAR_HIGH
    LEA DX, NORMAL_MSG_BS
    JMP PRINT_SUGAR
SUGAR_LOW:
    LEA DX, LOW_MSG_BS
    JMP PRINT_SUGAR
SUGAR_HIGH:
    LEA DX, HIGH_MSG_BS
PRINT_SUGAR:
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Systolic BP Row
    LEA DX, PARAM2
    MOV AH, 9
    INT 21H
    MOV AX, SYSTOLIC
    CALL PRINT_NUM
    LEA DX, SPACE
    MOV AH, 9
    INT 21H
    LEA DX, RANGE2
    MOV AH, 9
    INT 21H
    MOV AX, SYSTOLIC
    CMP AX, 90
    JL SYS_LOW
    CMP AX, 120
    JG SYS_HIGH
    LEA DX, NORMAL_MSG_BP
    JMP PRINT_SYS
SYS_LOW:
    LEA DX, LOW_MSG_BP
    JMP PRINT_SYS
SYS_HIGH:
    LEA DX, HIGH_MSG_BP
PRINT_SYS:
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Diastolic BP Row
    LEA DX, PARAM3
    MOV AH, 9
    INT 21H
    MOV AX, DIASTOLIC
    CALL PRINT_NUM
    LEA DX, SPACE
    MOV AH, 9
    INT 21H
    LEA DX, RANGE3
    MOV AH, 9
    INT 21H
    MOV AX, DIASTOLIC
    CMP AX, 60
    JL DIA_LOW
    CMP AX, 80
    JG DIA_HIGH
    LEA DX, NORMAL_MSG_BP
    JMP PRINT_DIA
DIA_LOW:
    LEA DX, LOW_MSG_BP
    JMP PRINT_DIA
DIA_HIGH:
    LEA DX, HIGH_MSG_BP
PRINT_DIA:
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    RET
DISPLAY_RESULTS1 ENDP

DISPLAY_RESULTS2 PROC
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    LEA DX, HEADER
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    LEA DX, LINE
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Oxygen Saturation Row
    LEA DX, PARAM4
    MOV AH, 9
    INT 21H
    MOV AX, OXYGEN
    CALL PRINT_NUM
    LEA DX, SPACE
    MOV AH, 9
    INT 21H
    LEA DX, RANGE4
    MOV AH, 9
    INT 21H
    MOV AX, OXYGEN
    CMP AX, 95
    JL OXY_LOW
    CMP AX, 100
    JG OXY_HIGH
    LEA DX, NORMAL_MSG_OS
    JMP PRINT_OXY
OXY_LOW:
    LEA DX, LOW_MSG_OS
    JMP PRINT_OXY
OXY_HIGH:
    LEA DX, HIGH_MSG_OS
PRINT_OXY:
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX

    ; Uric Acid Row
    LEA DX, PARAM5
    MOV AH, 9
    INT 21H
    MOV AL, URIC
    MOV AH, 0
    CALL PRINT_NUM
    LEA DX, SPACE
    MOV AH, 9
    INT 21H
    LEA DX, RANGE5
    MOV AH, 9
    INT 21H
    MOV AL, URIC
    MOV AH, 0
    CMP AL, 3
    JL URIC_LOW
    CMP AL, 7
    JG URIC_HIGH
    LEA DX, NORMAL_MSG_UA
    JMP PRINT_URIC
URIC_LOW:
    LEA DX, LOW_MSG_UA
    JMP PRINT_URIC
URIC_HIGH:
    LEA DX, HIGH_MSG_UA
PRINT_URIC:
    MOV AH, 9
    INT 21H
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    RET
DISPLAY_RESULTS2 ENDP

; -------- BMI formatting --------
DISPLAY_NUM PROC
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AX,BMI
    MOV DX,0
    MOV BX, 10
    DIV BX        ; AX=int, DX=dec
    PUSH DX

    MOV CX, 0
    MOV BX, 10
dint_div:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE dint_div
dint_out:
    POP DX
    ADD DL, '0'
    MOV AH, 2
    INT 21H
    LOOP dint_out

    MOV DL, '.'
    MOV AH, 2
    INT 21H

    POP DX
    ADD DL, '0'
    MOV AH, 2
    INT 21H

    POP DX
    POP CX
    POP BX
    RET
DISPLAY_NUM ENDP

CheckBMIStatus PROC
    MOV DL, ' '
    MOV AH, 2
    INT 21H
    MOV AX,BMI
    CMP AX, 185
    JL LowBMI
    CMP AX, 250
    JL NormalBMI
HighBMI:
    LEA DX, statusHigh
    JMP PrintBMIStatus
LowBMI:
    LEA DX, statusLow
    JMP PrintBMIStatus
NormalBMI:
    LEA DX, statusNormal
    JMP PrintBMIStatus
PrintBMIStatus:
    MOV AH, 9
    INT 21H
    RET
CheckBMIStatus ENDP

; ---- Assessors for Risk ----
ASSESS_SUGAR PROC
    PUSH BP
    MOV  BP, SP
    PUSH AX
    MOV  AX, [BP+4]
    CMP  AX, 70
    JL   asug_low
    CMP  AX, 90
    JLE  asug_normal
    MOV  AL, 2
    JMP  asug_ret
asug_low:    MOV  AL, 0
             JMP  asug_ret
asug_normal: MOV  AL, 1
asug_ret:
    POP  AX
    POP  BP
    RET  2
ASSESS_SUGAR ENDP

ASSESS_BP PROC
    PUSH BP
    MOV  BP, SP
    PUSH AX
    PUSH BX
    MOV  AX, [BP+4]     ; systolic
    MOV  BX, [BP+6]     ; diastolic
    MOV  AL, 1
    CMP  AX, 90
    JL   abp_low
    CMP  AX, 120
    JG   abp_high
    CMP  BX, 60
    JL   abp_low
    CMP  BX, 80
    JG   abp_high
    JMP  abp_done
abp_low:  MOV  AL, 0
          JMP  abp_done
abp_high: MOV  AL, 2
abp_done:
    POP  BX
    POP  AX
    POP  BP
    RET  4
ASSESS_BP ENDP

; ---- Rafid: BMR + Diet helpers ----
CALCULATE_BMR PROC
    PUSH BX
    PUSH DX
    CMP gender, 'M'
    JE MALE_BMR
    CMP gender, 'm'
    JE MALE_BMR

; FEMALE: 655 + 9.6W + 1.8H - 4.7A
FEMALE_BMR:
    MOV AX, 655
    MOV bmr, AX

    MOV AX, WEIGHT
    MOV BX, 96
    MUL BX
    MOV BX, 10
    DIV BX
    ADD bmr, AX

    MOV AX, HEIGHT
    MOV BX, 18
    MUL BX
    MOV BX, 10
    DIV BX
    ADD bmr, AX

    MOV AX, age
    MOV BX, 47
    MUL BX
    MOV BX, 10
    DIV BX
    SUB bmr, AX
    JMP BMR_DONE

; MALE: 66 + 13.7W + 5H - 6.8A
MALE_BMR:
    MOV AX, 66
    MOV bmr, AX

    MOV AX, WEIGHT
    MOV BX, 137
    MUL BX
    MOV BX, 10
    DIV BX
    ADD bmr, AX

    MOV AX, HEIGHT
    MOV BX, 5
    MUL BX
    ADD bmr, AX

    MOV AX, age
    MOV BX, 68
    MUL BX
    MOV BX, 10
    DIV BX
    SUB bmr, AX

BMR_DONE:
    POP DX
    POP BX
    RET
CALCULATE_BMR ENDP

CALCULATE_MACROS_BMR PROC
    PUSH BX
    PUSH DX
    MOV AX, bmr
    MOV BX, 25
    MUL BX
    MOV BX, 100
    DIV BX
    MOV veg_cals, AX

    MOV AX, bmr
    MOV BX, 50
    MUL BX
    MOV BX, 100
    DIV BX
    MOV pro_cals, AX

    MOV AX, bmr
    MOV BX, 25
    MUL BX
    MOV BX, 100
    DIV BX
    MOV fat_cals, AX
    POP DX
    POP BX
    RET
CALCULATE_MACROS_BMR ENDP

; Build "LLLL-HHHH$" for bmr bucket
CHECK_RANGES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV valid_range, 0
    MOV AX, bmr
    CMP AX, 300
    JB  CR_OUT
    CMP AX, 2400
    JAE CR_OUT

    SUB AX, 300
    MOV BX, 200
    MOV DX, 0
    DIV BX           ; AX = index 0..9

    ; L = 300 + i*200 ; H = L+200
    MOV BX, AX
    MOV AX, 200
    MUL BX
    ADD AX, 300
    MOV DX, AX       ; DX=L
    ADD AX, 200
    MOV BX, AX       ; BX=H

    ; write to range_str at ES:DI
    LEA DI, range_str
    MOV AX, DX
    CALL WRITE_4DIGITS_TO_DI
    MOV AL, '-'
    STOSB
    MOV AX, BX
    CALL WRITE_4DIGITS_TO_DI
    MOV AL, '$'
    STOSB

    MOV valid_range, 1
    JMP CR_DONE
CR_OUT:
CR_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CHECK_RANGES ENDP

; Write zero-padded 4 digits of AX to ES:DI
WRITE_4DIGITS_TO_DI PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 4
    MOV BX, 1000
W4_LOOP:
    MOV DX, 0
    DIV BX          ; AL=thousands/hundreds/tens/ones
    ADD AL, '0'
    STOSB
    MOV AX, DX
    CMP BX, 1000
    JE W4_SET100
    CMP BX, 100
    JE W4_SET10
    CMP BX, 10
    JE W4_SET1
    JMP W4_NEXT
W4_SET100: MOV BX, 100
    JMP W4_NEXT
W4_SET10:  MOV BX, 10
    JMP W4_NEXT
W4_SET1:   MOV BX, 1
W4_NEXT:
    LOOP W4_LOOP
    POP DX
    POP CX
    POP BX
    POP AX
    RET
WRITE_4DIGITS_TO_DI ENDP

; Random picks (no XOR/SHL: use MOV DX,0 and ADD BX,BX)
PRINT_RANDOM_VEG PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    MOV AH, 00h
    INT 1Ah
    MOV AX, DX
    MOV DX, 0
    MOV BX, 5
    DIV BX
    MOV BX, DX      ; remainder 0..4
    ADD BX, BX      ; *2
    LEA SI, veg_tab
    ADD SI, BX
    MOV DX, [SI]
    MOV AH, 9
    INT 21h
    POP SI
    POP DX
    POP BX
    POP AX
    RET
PRINT_RANDOM_VEG ENDP

PRINT_RANDOM_PRO PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    MOV AH, 00h
    INT 1Ah
    MOV AX, DX
    MOV DX, 0
    MOV BX, 5
    DIV BX
    MOV BX, DX
    ADD BX, BX
    LEA SI, pro_tab
    ADD SI, BX
    MOV DX, [SI]
    MOV AH, 9
    INT 21h
    POP SI
    POP DX
    POP BX
    POP AX
    RET
PRINT_RANDOM_PRO ENDP

PRINT_RANDOM_FAT PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    MOV AH, 00h
    INT 1Ah
    MOV AX, DX
    MOV DX, 0
    MOV BX, 5
    DIV BX
    MOV BX, DX
    ADD BX, BX
    LEA SI, fat_tab
    ADD SI, BX
    MOV DX, [SI]
    MOV AH, 9
    INT 21h
    POP SI
    POP DX
    POP BX
    POP AX
    RET
PRINT_RANDOM_FAT ENDP

END MAIN
