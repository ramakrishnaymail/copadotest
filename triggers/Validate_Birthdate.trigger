trigger Validate_Birthdate on Physician_Portal_Office_Agreement_gne__c (before insert, before update) 
{
    
    for (Physician_Portal_Office_Agreement_gne__c poa :trigger.new)
    {
        if(poa.Birth_Month_and_Day_MM_DD_gne__c !=null)
        {
            Pattern MyPattern = Pattern.compile('(0[1-9]|1[012])[/](0[1-9]|[12][0-9]|3[01])');
            Matcher MyMatcher = MyPattern.matcher(poa.Birth_Month_and_Day_MM_DD_gne__c);
            System.debug('Pattern result is ***********' + MyMatcher.matches());
            if (MyMatcher.matches() == False)
            {
                poa.adderror('Please enter correct value for Birth Month and Day field in MM/DD format.');
            }
            else
            {
                String[] datestringsarray = poa.Birth_Month_and_Day_MM_DD_gne__c.split('/');
                if (datestringsarray[0] == '02')
                 {
                     if (Integer.valueOf(datestringsarray[1]) > 29)
                      {
                          poa.adderror('FEBRUARY CANNOT HAVE MORE THAN 29 DAYS.');
                      }
                 }                 
                 if (datestringsarray[0] == '04' || datestringsarray[0] == '06' || datestringsarray[0] == '09'
                      || datestringsarray[0] == '11')
                 {
                    if (Integer.valueOf(datestringsarray[1]) > 30)
                      {
                          poa.adderror('Number of days have to be less than or equal to 30.');
                      }
                 }

             }
         }
     }
}