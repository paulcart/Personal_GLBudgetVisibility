pageextension 50300 "CoA Budget" extends "Chart of Accounts"
{
    layout
    {
        addafter(Balance)
        {
            field("Budgeted Amount"; "Budgeted Amount")
            {
                ApplicationArea = All;
                BlankZero = true;
            }
            field("Remaining Budget"; RemainingBudget)
            {
                ApplicationArea = All;
                BlankZero = true;
                Editable = false;
                StyleExpr = RemainingBudgetStyle;
            }
            field(Prediction; EndOfMonthPrediction)
            {
                CaptionClass = PredictionCaption;
                ApplicationArea = All;
                BlankZero = true;
                Editable = false;
                StyleExpr = EndOfMonthPredictionStyle;
            }
        }
    }

    var
        RemainingBudget: Decimal;
        RemainingBudgetStyle: Text;
        EndOfMonthPrediction: Decimal;

        RemainingBudgetEndOfMonth: Decimal;
        EndOfMonthPredictionStyle: Text;
        CurrDateFilter: Text;
        DaysInPeriod: Integer;
        CurrentDay: Integer;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        PredictionCaption: Text;

    trigger OnAfterGetRecord()
    begin
        CalculateDaysThroughPeriod();
        CalcEndOfMonthPrediction();
        CalcRemainingBudget();
    end;

    local procedure CalculateDaysThroughPeriod()
    var
        Date: Record Date;
    begin
        if CurrDateFilter = GetFilter("Date Filter") then begin
            exit;
        end else begin
            CurrDateFilter := GetFilter("Date Filter");
        end;

        if CurrDateFilter = '' then begin
            PeriodStartDate := 0D;
            PeriodEndDate := 0D;
            DaysInPeriod := 0;
            CurrentDay := 0;
            PredictionCaption := 'No Prediction';
            exit;
        end;

        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", GetFilter("Date Filter"));
        date.FindFirst();
        PeriodStartDate := date."Period Start";
        date.FindLast();
        PeriodEndDate := date."Period Start";

        if (PeriodStartDate > WorkDate()) or (PeriodEndDate < WorkDate()) then begin
            PeriodStartDate := 0D;
            PeriodEndDate := 0D;
            DaysInPeriod := 0;
            CurrentDay := 0;
            PredictionCaption := 'No Prediction';
            exit;
        end;

        CurrentDay := WorkDate() - PeriodStartDate;
        DaysInPeriod := PeriodEndDate - PeriodStartDate;
        PredictionCaption := StrSubstNo('Prediction (Day %1 of %2)', CurrentDay, DaysInPeriod);

    end;

    local procedure CalcEndOfMonthPrediction()
    var
        NetChangePerDay: Decimal;
    begin

        if (CurrentDay = 0) or ("Account Type" <> "Account Type"::Posting) then begin
            EndOfMonthPrediction := 0;
        end else begin
            case "End of Month Prediction" of
                "End of Month Prediction"::"Current Value":
                    begin
                        EndOfMonthPrediction := "Net Change";
                    end;

                "End of Month Prediction"::"Budgeted Amount":
                    begin
                        if "Net Change" > "Budgeted Amount" then begin
                            EndOfMonthPrediction := "Net Change";
                        end else begin
                            EndOfMonthPrediction := "Budgeted Amount";
                        end;
                    end;

                "End of Month Prediction"::"Same Amount Each Day":
                    begin
                        NetChangePerDay := "Net Change" / CurrentDay;
                        EndOfMonthPrediction := NetChangePerDay * DaysInPeriod;
                    end;
            end;
        end;
    end;

    local procedure CalcRemainingBudget()
    begin
        if ("Budgeted Amount" = 0) or ("Account Type" <> "Account Type"::Posting) then begin
            RemainingBudget := 0;
            RemainingBudgetStyle := 'None';
        end else begin
            RemainingBudget := "Budgeted Amount" - "Net Change";
            RemainingBudgetEndOfMonth := "Budgeted Amount" - EndOfMonthPrediction;

            if RemainingBudget = 0 then begin
                RemainingBudgetStyle := 'None';
            end else begin
                if RemainingBudget < 0 then begin
                    RemainingBudgetStyle := 'Unfavorable';
                end else begin
                    RemainingBudgetStyle := 'Favorable';
                end;
            end;

            if RemainingBudgetEndOfMonth = 0 then begin
                RemainingBudgetStyle := 'None';
            end else begin
                if RemainingBudgetEndOfMonth < 0 then begin
                    EndOfMonthPredictionStyle := 'Unfavorable';
                end else begin
                    EndOfMonthPredictionStyle := 'Favorable';
                end;
            end;
        end;
    end;
}