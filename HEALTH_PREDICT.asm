.MODEL SMALL
.STACK 200H
.DATA 
    ; Menu Messages
    MENU_MSG DB '*** HEALTH PREDICT+ ***$'
    MENU_1 DB '1. Medical History Monitor$'
    MENU_2 DB '2. BMI Calculator$'
    MENU_3 DB '3. Advanced Caloric Calculator$'
    MENU_4 DB '4. Diet Chart Generator$'
    MENU_5 DB '5. Exit$'
    CHOICE_MSG DB 'Enter your choice (1-5): $'
    
    ; Medical History Variables (keeping existing)
    MSG1 DB 'Enter Blood Sugar (mg/dL) in 2 digits: $'
    MSG2 DB 'Enter Systolic BP (mmHg) digits choice [2 for 2 digits/3 for 3 digits]: $'
    MSG3 DB 'Enter Systolic BP (mmHg): $'
    MSG4 DB 'Enter Diastolic BP (mmHg) in 2 digits: $'
    MSG5 DB 'Enter Oxygen Saturation (%) in 2 digits: $'
    MSG6 DB 'Enter Uric Acid (mg/dL) in 1 digit: $'
    
    NEWLINE DB 0DH,0AH,'$'
    SPACE DB '  $'
    
    SUGAR DW ?
    SYSTOLIC DW ?
    DIASTOLIC DW ?
    OXYGEN DW ?
    URIC DB ?
    CHOICE DB ?
    
    ; BMI Variables
    PROMPT_HEIGHT DB 'Enter height (1 for cm, 2 for inch): $'
    PROMPT_CM DB 'Enter height in cm (3 digits): $'
    PROMPT_INCH DB 'Enter height in inches (2 digits): $'
    PROMPT_WEIGHT DB 'Enter weight (1 for kg, 2 for lb): $'
    PROMPT_KG DB 'Enter weight in kg (2 digits): $'
    PROMPT_LB DB 'Enter weight in lb (3 digits): $'
    BMI_MSG DB 'Your BMI is: $'
    HEIGHT DW ?    
    WEIGHT DW ?    
    BMI DW ?
    
    ; Enhanced Calorie Calculator Variables
    prompt_age DB 'Enter age in years (2 digits): $'
    prompt_gender DB 'Enter gender (M/F): $'
    prompt_activity DB 0DH,0AH,'Activity Level:',0DH,0AH
                    DB '1. Sedentary (little/no exercise)',0DH,0AH
                    DB '2. Light (1-3 days/week)',0DH,0AH
                    DB '3. Moderate (3-5 days/week)',0DH,0AH
                    DB '4. Active (6-7 days/week)',0DH,0AH
                    DB '5. Very Active (physical job)',0DH,0AH
                    DB 'Enter choice (1-5): $'
    
    age DW ?
    gender DB ?
    activity_level DB ?
    bmr DW ?
    tdee DW ?
    
    ; Activity multiplier array (multiplied by 100 for precision)
    activity_mult DW 120, 138, 155, 173, 190  ; 1.2, 1.375, 1.55, 1.725, 1.9
    
    result_msg DB 'Your Basal Metabolic Rate (BMR): $'
    tdee_msg DB 0DH,0AH,'Total Daily Energy Expenditure (TDEE): $'
    
    ; Diet Chart Variables
    diet_header DB 0DH,0AH,'*** PERSONALIZED DIET CHART ***',0DH,0AH,'$'
    diet_line DB '----------------------------------------',0DH,0AH,'$'
    
    ; Meal names array
    meal_names DB 'Breakfast:     $'
              DB 'Morning Snack: $'
              DB 'Lunch:         $'
              DB 'Evening Snack: $'
              DB 'Dinner:        $'
    
    ; Meal calorie percentages (out of 100)
    meal_percent DB 25, 10, 35, 10, 20
    
    ; Food arrays for each meal type
    breakfast_foods DB 'Oatmeal with fruits    $'
                   DB 'Eggs with whole wheat  $'
                   DB 'Greek yogurt parfait   $'
                   DB 'Smoothie bowl          $'
                   DB 'Avocado toast          $'
    
    snack_foods DB 'Apple with almonds     $'
               DB 'Protein bar            $'
               DB 'Mixed nuts             $'
               DB 'Banana with peanut butter$'
               DB 'Carrot sticks & hummus $'
    
    lunch_foods DB 'Grilled chicken salad  $'
               DB 'Brown rice & vegetables$'
               DB 'Quinoa bowl            $'
               DB 'Fish with sweet potato $'
               DB 'Lentil soup & bread    $'
    
    dinner_foods DB 'Salmon with vegetables $'
                DB 'Chicken stir-fry       $'
                DB 'Turkey meatballs pasta $'
                DB 'Tofu curry with rice   $'
                DB 'Beef with quinoa       $'
    
    ; Stack for meal calculations
    meal_calories DW 5 DUP(0)  ; Initialize to 0
    stack_ptr DW 0
    
    ; Calorie display messages
    calories_msg DB ' calories$'
    meal_cal_msg DB 'Meal Calories: $'
    
    ; Nutrition tips array
    tips_msg DB 0DH,0AH,'Nutrition Tips:',0DH,0AH,'$'
    tip1 DB '- Drink 8-10 glasses of water daily',0DH,0AH,'$'
    tip2 DB '- Include protein in every meal',0DH,0AH,'$'
    tip3 DB '- Eat vegetables with every meal',0DH,0AH,'$'
    tip4 DB '- Avoid processed foods',0DH,0AH,'$'
    tip5 DB '- Get adequate sleep for metabolism',0DH,0AH,'$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    ; Initialize variables to prevent undefined values
    MOV tdee, 0
    MOV bmr, 0
    
MENU:
    ; Clear screen effect with multiple newlines
    MOV CX, 3
CLEAR_LOOP:
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    LOOP CLEAR_LOOP
    
    ; Display menu
    LEA DX, MENU_MSG
    MOV AH, 9
    INT 21H
    CALL PRINT_NEWLINE
    
    LEA DX, MENU_1
    MOV AH, 9
    INT 21H
    CALL PRINT_NEWLINE
    
    LEA DX, MENU_2
    MOV AH, 9
    INT 21H
    CALL PRINT_NEWLINE
    
    LEA DX, MENU_3
    MOV AH, 9
    INT 21H
    CALL PRINT_NEWLINE
    
    LEA DX, MENU_4
    MOV AH, 9
    INT 21H
    CALL PRINT_NEWLINE
    
    LEA DX, MENU_5
    MOV AH, 9
    INT 21H
    CALL PRINT_NEWLINE
    
    LEA DX, CHOICE_MSG
    MOV AH, 9
    INT 21H
    
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    
    CMP AL, 1
    JE MEDICAL_HISTORY
    CMP AL, 2
    JE BMI_CALC
    CMP AL, 3
    JE ADVANCED_CALORIC
    CMP AL, 4
    JE DIET_GENERATOR
    CMP AL, 5
    JE EXIT_PROGRAM
    JMP MENU
    
MEDICAL_HISTORY:
    CALL PRINT_NEWLINE
    ; Placeholder for medical history functionality
    LEA DX, MSG1
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    MOV SUGAR, AX
    CALL PRINT_NEWLINE
    JMP MENU
    
BMI_CALC:
    CALL PRINT_NEWLINE
    ; Placeholder for BMI calculation functionality
    LEA DX, PROMPT_HEIGHT
    MOV AH, 9
    INT 21H
    CALL PRINT_NEWLINE
    JMP MENU
    
ADVANCED_CALORIC:
    CALL PRINT_NEWLINE
    
    ; Get Age
    LEA DX, prompt_age
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    
    ; Validate age (reasonable range 10-120)
    CMP AX, 10
    JB SET_DEFAULT_AGE
    CMP AX, 120
    JA SET_DEFAULT_AGE
    JMP AGE_OK
    
SET_DEFAULT_AGE:
    MOV AX, 25  ; Default age
    
AGE_OK:
    MOV age, AX
    CALL PRINT_NEWLINE
    
    ; Get Gender
    LEA DX, prompt_gender
    MOV AH, 9
    INT 21H
    MOV AH, 1
    INT 21H
    MOV gender, AL
    CALL PRINT_NEWLINE
    
    ; Get Height
    LEA DX, PROMPT_HEIGHT
    MOV AH, 9
    INT 21H
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    
    CMP AL, 1
    JE CM_CAL
    JMP INCH_CAL
    
CM_CAL:
    CALL PRINT_NEWLINE
    LEA DX, PROMPT_CM
    MOV AH, 9
    INT 21H
    CALL READ_THREE_DIGITS
    ; Validate height in cm (100-250)
    CMP AX, 100
    JB SET_DEFAULT_HEIGHT_CM
    CMP AX, 250
    JA SET_DEFAULT_HEIGHT_CM
    JMP HEIGHT_OK
    
SET_DEFAULT_HEIGHT_CM:
    MOV AX, 170  ; Default height in cm
    JMP HEIGHT_OK
    
INCH_CAL:
    CALL PRINT_NEWLINE
    LEA DX, PROMPT_INCH
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    ; Validate height in inches (48-84)
    CMP AX, 48
    JB SET_DEFAULT_HEIGHT_INCH
    CMP AX, 84
    JA SET_DEFAULT_HEIGHT_INCH
    
    ; Convert inches to cm safely
    MOV BX, 254
    MUL BX
    ; Check for overflow before division
    CMP DX, 0
    JNE SET_DEFAULT_HEIGHT_INCH
    MOV BX, 100
    DIV BX
    JMP HEIGHT_OK
    
SET_DEFAULT_HEIGHT_INCH:
    MOV AX, 170  ; Default height in cm
    
HEIGHT_OK:
    MOV HEIGHT, AX
    
WEIGHT_CAL:
    CALL PRINT_NEWLINE
    LEA DX, PROMPT_WEIGHT
    MOV AH, 9
    INT 21H
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    
    CMP AL, 1
    JE KG_CAL
    JMP LB_CAL
    
KG_CAL:
    CALL PRINT_NEWLINE
    LEA DX, PROMPT_KG
    MOV AH, 9
    INT 21H
    CALL READ_TWO_DIGITS
    ; Validate weight in kg (30-200)
    CMP AX, 30
    JB SET_DEFAULT_WEIGHT_KG
    CMP AX, 200
    JA SET_DEFAULT_WEIGHT_KG
    JMP WEIGHT_OK
    
SET_DEFAULT_WEIGHT_KG:
    MOV AX, 70  ; Default weight in kg
    JMP WEIGHT_OK
    
LB_CAL:
    CALL PRINT_NEWLINE
    LEA DX, PROMPT_LB
    MOV AH, 9
    INT 21H
    CALL READ_THREE_DIGITS
    ; Validate weight in lb (66-440)
    CMP AX, 66
    JB SET_DEFAULT_WEIGHT_LB
    CMP AX, 440
    JA SET_DEFAULT_WEIGHT_LB
    
    ; Convert lb to kg safely
    MOV BX, 45
    MUL BX
    ; Check for overflow
    CMP DX, 0
    JNE SET_DEFAULT_WEIGHT_LB
    MOV BX, 100
    DIV BX
    JMP WEIGHT_OK
    
SET_DEFAULT_WEIGHT_LB:
    MOV AX, 70  ; Default weight in kg
    
WEIGHT_OK:
    MOV WEIGHT, AX
    
GET_ACTIVITY:
    CALL PRINT_NEWLINE
    LEA DX, prompt_activity
    MOV AH, 9
    INT 21H
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    
    ; Validate activity level (1-5)
    CMP AL, 1
    JB SET_DEFAULT_ACTIVITY
    CMP AL, 5
    JA SET_DEFAULT_ACTIVITY
    JMP ACTIVITY_OK
    
SET_DEFAULT_ACTIVITY:
    MOV AL, 2  ; Default to light activity
    
ACTIVITY_OK:
    MOV activity_level, AL
    
    ; Calculate BMR using Harris-Benedict Formula
    CALL CALCULATE_BMR
    
    ; Calculate TDEE
    CALL CALCULATE_TDEE
    
    ; Display results
    CALL PRINT_NEWLINE
    LEA DX, result_msg
    MOV AH, 9
    INT 21H
    MOV AX, bmr
    CALL PRINT_NUM
    LEA DX, calories_msg
    MOV AH, 9
    INT 21H
    
    LEA DX, tdee_msg
    MOV AH, 9
    INT 21H
    MOV AX, tdee
    CALL PRINT_NUM
    LEA DX, calories_msg
    MOV AH, 9
    INT 21H
    
    CALL PRINT_NEWLINE
    JMP MENU
    
DIET_GENERATOR:
    CALL PRINT_NEWLINE
    
    ; Check if TDEE is calculated and valid
    MOV AX, tdee
    CMP AX, 0
    JE SET_DEFAULT_TDEE
    CMP AX, 1000
    JB SET_DEFAULT_TDEE
    CMP AX, 5000
    JA SET_DEFAULT_TDEE
    JMP TDEE_OK
    
SET_DEFAULT_TDEE:
    MOV tdee, 2000  ; Safe default value
    
TDEE_OK:
    ; Display diet header
    LEA DX, diet_header
    MOV AH, 9
    INT 21H
    LEA DX, diet_line
    MOV AH, 9
    INT 21H
    
    ; Calculate meal calories using stack
    CALL CALCULATE_MEAL_CALORIES
    
    ; Generate and display diet chart
    CALL DISPLAY_DIET_CHART
    
    ; Display nutrition tips
    CALL DISPLAY_TIPS
    
    CALL PRINT_NEWLINE
    JMP MENU
    
EXIT_PROGRAM:
    MOV AH, 4CH
    INT 21H
MAIN ENDP

; Calculate BMR using Harris-Benedict Formula
CALCULATE_BMR PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Ensure we have valid values
    MOV AX, weight
    CMP AX, 0
    JE BMR_ERROR
    MOV AX, height
    CMP AX, 0
    JE BMR_ERROR
    MOV AX, age
    CMP AX, 0
    JE BMR_ERROR
    
    CMP gender, 'M'
    JE MALE_BMR
    CMP gender, 'm'
    JE MALE_BMR
    
FEMALE_BMR:
    ; BMR = 655 + (9.6 × weight) + (1.8 × height) - (4.7 × age)
    MOV AX, 655
    MOV bmr, AX
    
    ; Add 9.6 × weight (using 96/10)
    MOV AX, weight
    MOV BX, 96
    MUL BX
    CMP DX, 0  ; Check for overflow
    JNE BMR_ERROR
    MOV BX, 10
    DIV BX
    ADD bmr, AX
    
    ; Add 1.8 × height (using 18/10)
    MOV AX, height
    MOV BX, 18
    MUL BX
    CMP DX, 0  ; Check for overflow
    JNE BMR_ERROR
    MOV BX, 10
    DIV BX
    ADD bmr, AX
    
    ; Subtract 4.7 × age (using 47/10)
    MOV AX, age
    MOV BX, 47
    MUL BX
    CMP DX, 0  ; Check for overflow
    JNE BMR_ERROR
    MOV BX, 10
    DIV BX
    SUB bmr, AX
    JMP BMR_DONE
    
MALE_BMR:
    ; BMR = 66 + (13.7 × weight) + (5 × height) - (6.8 × age)
    MOV AX, 66
    MOV bmr, AX
    
    ; Add 13.7 × weight (using 137/10)
    MOV AX, weight
    MOV BX, 137
    MUL BX
    CMP DX, 0  ; Check for overflow
    JNE BMR_ERROR
    MOV BX, 10
    DIV BX
    ADD bmr, AX
    
    ; Add 5 × height
    MOV AX, height
    MOV BX, 5
    MUL BX
    CMP DX, 0  ; Check for overflow
    JNE BMR_ERROR
    ADD bmr, AX
    
    ; Subtract 6.8 × age (using 68/10)
    MOV AX, age
    MOV BX, 68
    MUL BX
    CMP DX, 0  ; Check for overflow
    JNE BMR_ERROR
    MOV BX, 10
    DIV BX
    SUB bmr, AX
    JMP BMR_DONE
    
BMR_ERROR:
    MOV bmr, 1500  ; Safe default BMR
    
BMR_DONE:
    ; Ensure BMR is reasonable
    MOV AX, bmr
    CMP AX, 800
    JB SET_MIN_BMR
    CMP AX, 3000
    JA SET_MAX_BMR
    JMP BMR_VALID
    
SET_MIN_BMR:
    MOV bmr, 1200
    JMP BMR_VALID
    
SET_MAX_BMR:
    MOV bmr, 2500
    
BMR_VALID:
    POP DX
    POP CX
    POP BX
    RET
CALCULATE_BMR ENDP

; Calculate TDEE based on activity level
CALCULATE_TDEE PROC
    PUSH BX
    PUSH SI
    
    ; Validate activity level
    MOV BL, activity_level
    CMP BL, 1
    JB TDEE_ERROR
    CMP BL, 5
    JA TDEE_ERROR
    
    ; Ensure BMR is valid
    MOV AX, bmr
    CMP AX, 0
    JE TDEE_ERROR
    
    ; Get activity multiplier from array
    DEC BL  ; Convert to 0-based index
    MOV BH, 0
    SHL BX, 1  ; Multiply by 2 for word access
    LEA SI, activity_mult
    ADD SI, BX
    MOV BX, [SI]  ; Get multiplier
    
    ; Calculate TDEE = BMR × activity_multiplier
    MOV AX, bmr
    MUL BX
    CMP DX, 0  ; Check for overflow
    JNE TDEE_ERROR
    MOV BX, 100
    DIV BX
    MOV tdee, AX
    JMP TDEE_DONE
    
TDEE_ERROR:
    MOV tdee, 2000  ; Safe default TDEE
    
TDEE_DONE:
    POP SI
    POP BX
    RET
CALCULATE_TDEE ENDP

; Calculate calories for each meal using stack
CALCULATE_MEAL_CALORIES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    
    ; Ensure TDEE is valid before calculation
    MOV AX, tdee
    CMP AX, 0
    JE MEAL_CAL_ERROR
    CMP AX, 1000
    JB MEAL_CAL_ERROR
    CMP AX, 5000
    JA MEAL_CAL_ERROR
    JMP MEAL_CAL_OK
    
MEAL_CAL_ERROR:
    MOV tdee, 2000  ; Safe default
    
MEAL_CAL_OK:
    MOV stack_ptr, 0
    LEA SI, meal_percent
    MOV CX, 5
    
CALC_MEAL_LOOP:
    MOV AL, [SI]
    MOV AH, 0
    
    ; Validate percentage (should be 1-50)
    CMP AL, 0
    JE SKIP_MEAL
    CMP AL, 50
    JA SKIP_MEAL
    
    MOV BX, tdee
    MUL BX
    
    ; Check for overflow in multiplication
    CMP DX, 0
    JNE MEAL_OVERFLOW
    
    ; Safe division by 100
    MOV BX, 100
    DIV BX
    JMP STORE_MEAL
    
MEAL_OVERFLOW:
SKIP_MEAL:
    ; Use default calorie value
    MOV AX, 300
    
STORE_MEAL:
    ; Push to meal stack
    MOV BX, stack_ptr
    CMP BX, 5  ; Safety check
    JGE MEAL_DONE
    SHL BX, 1
    MOV meal_calories[BX], AX
    INC stack_ptr
    
    INC SI
    LOOP CALC_MEAL_LOOP
    
MEAL_DONE:
    POP SI
    POP CX
    POP BX
    POP AX
    RET
CALCULATE_MEAL_CALORIES ENDP

; Display personalized diet chart
DISPLAY_DIET_CHART PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    MOV CX, 5  ; 5 meals
    MOV SI, 0
    
DISPLAY_MEAL_LOOP:
    ; Display meal name
    MOV AX, SI
    MOV BX, 16  ; Each meal name is 16 bytes
    MUL BX
    LEA DX, meal_names
    ADD DX, AX
    MOV AH, 9
    INT 21H
    
    ; Display food recommendation
    CALL GET_FOOD_RECOMMENDATION
    
    ; Display calories for this meal
    LEA DX, meal_cal_msg
    MOV AH, 9
    INT 21H
    
    MOV BX, SI
    CMP BX, 5  ; Safety check
    JGE SKIP_DISPLAY
    SHL BX, 1
    MOV AX, meal_calories[BX]
    CALL PRINT_NUM
    
    LEA DX, calories_msg
    MOV AH, 9
    INT 21H
    
SKIP_DISPLAY:
    CALL PRINT_NEWLINE
    
    INC SI
    LOOP DISPLAY_MEAL_LOOP
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_DIET_CHART ENDP

; Get food recommendation based on meal type
GET_FOOD_RECOMMENDATION PROC
    PUSH AX
    PUSH BX
    PUSH DX
    
    ; Simple rotation based on meal index
    MOV AX, SI
    MOV BL, 5
    DIV BL
    MOV AL, AH  ; Get remainder (0-4)
    
    MOV BL, 25  ; Each food string is 25 bytes
    MUL BL
    
    CMP SI, 0
    JE BREAKFAST_FOOD
    CMP SI, 1
    JE SNACK_FOOD
    CMP SI, 2
    JE LUNCH_FOOD
    CMP SI, 3
    JE SNACK_FOOD
    JMP DINNER_FOOD
    
BREAKFAST_FOOD:
    LEA DX, breakfast_foods
    JMP DISPLAY_FOOD
    
SNACK_FOOD:
    LEA DX, snack_foods
    JMP DISPLAY_FOOD
    
LUNCH_FOOD:
    LEA DX, lunch_foods
    JMP DISPLAY_FOOD
    
DINNER_FOOD:
    LEA DX, dinner_foods
    
DISPLAY_FOOD:
    ADD DX, AX
    MOV AH, 9
    INT 21H
    
    POP DX
    POP BX
    POP AX
    RET
GET_FOOD_RECOMMENDATION ENDP

; Display nutrition tips
DISPLAY_TIPS PROC
    PUSH DX
    
    CALL PRINT_NEWLINE
    LEA DX, tips_msg
    MOV AH, 9
    INT 21H
    
    LEA DX, tip1
    MOV AH, 9
    INT 21H
    
    LEA DX, tip2
    MOV AH, 9
    INT 21H
    
    LEA DX, tip3
    MOV AH, 9
    INT 21H
    
    LEA DX, tip4
    MOV AH, 9
    INT 21H
    
    LEA DX, tip5
    MOV AH, 9
    INT 21H
    
    POP DX
    RET
DISPLAY_TIPS ENDP

; Utility Procedures
READ_TWO_DIGITS PROC
    PUSH BX
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    
    ; Validate first digit
    CMP AL, 9
    JA READ_ERROR_2D
    MOV BL, AL
    
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    
    ; Validate second digit
    CMP AL, 9
    JA READ_ERROR_2D
    
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
    
READ_ERROR_2D:
    MOV AX, 0  ; Return 0 on error
    POP BX
    RET
READ_TWO_DIGITS ENDP

READ_THREE_DIGITS PROC
    PUSH BX
    PUSH CX
    
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    CMP AL, 9
    JA READ_ERROR_3D
    MOV BL, AL
    
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    CMP AL, 9
    JA READ_ERROR_3D
    MOV CL, AL
    
    MOV AH, 1
    INT 21H
    SUB AL, '0'
    CMP AL, 9
    JA READ_ERROR_3D
    
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
    
READ_ERROR_3D:
    MOV AX, 0  ; Return 0 on error
    POP CX
    POP BX
    RET
READ_THREE_DIGITS ENDP

PRINT_NUM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Handle zero case
    CMP AX, 0
    JNE NOT_ZERO
    MOV DL, '0'
    MOV AH, 2
    INT 21H
    JMP PRINT_DONE
    
NOT_ZERO:
    MOV CX, 0
    MOV BX, 10
    
DIVIDE:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE DIVIDE
    
PRINT_DIGITS:
    POP DX
    ADD DL, '0'
    MOV AH, 2
    INT 21H
    LOOP PRINT_DIGITS
    
PRINT_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUM ENDP

PRINT_NEWLINE PROC
    PUSH DX
    LEA DX, NEWLINE
    MOV AH, 9
    INT 21H
    POP DX
    RET
PRINT_NEWLINE ENDP

END MAIN