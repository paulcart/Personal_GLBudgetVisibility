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
        }
    }

    var
        RemainingBudget: Decimal;
        RemainingBudgetStyle: Text;

    trigger OnAfterGetRecord()
    begin
        CalcRemainingBudget();
    end;

    local procedure CalcRemainingBudget()
    begin
        // CalcFields("Budgeted Amount");
        // CalcFields("Net Change");
        if "Budgeted Amount" = 0 then begin
            RemainingBudget := 0;
            RemainingBudgetStyle := 'None';
        end else begin
            RemainingBudget := "Budgeted Amount" - "Net Change";
            if RemainingBudget = 0 then begin
                RemainingBudgetStyle := 'None';
            end else begin
                if RemainingBudget < 0 then begin
                    RemainingBudgetStyle := 'Unfavorable';
                end else begin
                    RemainingBudgetStyle := 'Favorable';
                end;
            end;
        end;
    end;
}