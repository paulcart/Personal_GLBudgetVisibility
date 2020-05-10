pageextension 50301 "G/L Account BudgVis" extends "G/L Account Card"
{
    layout
    {
        addlast(General)
        {
            field("End of Month Prediction"; "End of Month Prediction")
            {
                ApplicationArea = All;
            }
        }
    }
}