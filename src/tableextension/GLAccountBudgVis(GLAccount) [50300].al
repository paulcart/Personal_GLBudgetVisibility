tableextension 50300 "G/L Account BudgVis" extends "G/L Account"
{
    fields
    {
        field(50300; "End of Month Prediction"; Enum "End of Month Prediction")
        {

        }
    }

    var
        CurrDateFilter: Text;
        DaysInPeriod: Integer;
        CurrentDay: Integer;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        PredictionCaption: Text;

    procedure EndOfMonthPrediction(): Decimal
    var
    begin
        CalculateDaysThroughPeriod();
        exit(CalcEndOfMonthPrediction());
    end;

    procedure GetPredictionCaption(): Text;
    begin
        CalculateDaysThroughPeriod();
        exit(PredictionCaption);
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

    local procedure CalcEndOfMonthPrediction(): Decimal
    var
        NetChangePerDay: Decimal;
    begin

        if (CurrentDay = 0) then begin
            exit(0);
        end;

        if "Account Type" = "Account Type"::Posting then begin
            case "End of Month Prediction" of
                "End of Month Prediction"::"None":
                    begin
                        exit(0);
                    end;

                "End of Month Prediction"::"Current Value":
                    begin
                        exit("Net Change");
                    end;

                "End of Month Prediction"::"Budgeted Amount":
                    begin
                        if "Budgeted Amount" >= 0 then begin
                            if "Net Change" > "Budgeted Amount" then begin
                                exit("Net Change");
                            end else begin
                                exit("Budgeted Amount");
                            end;
                        end else begin
                            if "Net Change" < "Budgeted Amount" then begin
                                exit("Net Change");
                            end else begin
                                exit("Budgeted Amount");
                            end;
                        end;
                    end;

                "End of Month Prediction"::"Same Amount Each Day":
                    begin
                        NetChangePerDay := "Net Change" / CurrentDay;
                        exit(NetChangePerDay * DaysInPeriod);
                    end;
            end;
        end;

        if "Account Type" = "Account Type"::"End-Total" then begin
            exit(CalcEndOfMonthPrediction_EndTotal());
        end;

        exit(0);
    end;

    local procedure CalcEndOfMonthPrediction_EndTotal() TotalledPrediction: Decimal
    var
        GLAccountToBeTotalled: Record "G/L Account";
    begin
        //GLAccountToBeTotalled.SetView(rec.GetView());
        GLAccountToBeTotalled.SetFilter("Date Filter", rec.GetFilter("Date Filter"));
        GLAccountToBeTotalled.SetFilter("No.", rec.Totaling);
        GLAccountToBeTotalled.SetRange("Account Type", "Account Type"::Posting);

        if GLAccountToBeTotalled.FindSet() then begin
            repeat
                GLAccountToBeTotalled.CalcFields("Net Change", "Budgeted Amount");
                TotalledPrediction += GLAccountToBeTotalled.EndOfMonthPrediction();
            until GLAccountToBeTotalled.Next() = 0;
        end;
    end;
}