//
//  EKRecurrenceRule+RRULE.m
//  RRULE
//
//  Created by Jochen Schöllig on 24.04.13.
//  Copyright (c) 2013 Jochen Schöllig. All rights reserved.
//

#import "EKRecurrenceRule+RRULE.h"

static NSDateFormatter *dateFormatter = nil;


@implementation EKRecurrenceRule (RRULE)

- (EKRecurrenceRule *)initWithString:(NSString *)rfc2445String
{
    return [self initWithString:rfc2445String andParseMore:NO];
}

- (EKRecurrenceRule *)initWithString:(NSString *)rfc2445String andParseMore:(BOOL)more
{
    // If the date formatter isn't already set up, create it and cache it for reuse.
    if (dateFormatter == nil)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSXXX"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    // Begin parsing
    NSArray *components = [rfc2445String.uppercaseString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";="]];

    EKRecurrenceFrequency frequency = EKRecurrenceFrequencyDaily;
    NSInteger interval              = 1;
    NSMutableArray *daysOfTheWeek   = nil;
    NSMutableArray *daysOfTheMonth  = nil;
    NSMutableArray *monthsOfTheYear = nil;
    NSMutableArray *daysOfTheYear   = nil;
    NSMutableArray *weeksOfTheYear  = nil;
    NSMutableArray *setPositions    = nil;
    EKRecurrenceEnd *recurrenceEnd  = nil;
    
    for (int i = 0; i < components.count; i++)
    {
        NSString *component = [components objectAtIndex:i];
        
        // Frequency
        if ([component isEqualToString:@"FREQ"])
        {
            NSString *frequencyString = [components objectAtIndex:++i];
            
            if      ([frequencyString isEqualToString:@"DAILY"])   frequency = EKRecurrenceFrequencyDaily;
            else if ([frequencyString isEqualToString:@"WEEKLY"])  frequency = EKRecurrenceFrequencyWeekly;
            else if ([frequencyString isEqualToString:@"MONTHLY"]) frequency = EKRecurrenceFrequencyMonthly;
            else if ([frequencyString isEqualToString:@"YEARLY"])  frequency = EKRecurrenceFrequencyYearly;
        }
    
        // Interval
        else if ([component isEqualToString:@"INTERVAL"])
        {
            interval = [[components objectAtIndex:++i] intValue];
        }
        
        // Days of the week
        else if ([component isEqualToString:@"BYDAY"])
        {
            daysOfTheWeek = [NSMutableArray array];
            NSArray *dayStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *dayString in dayStrings)
            {
                int dayOfWeek = 0;
                int weekNumber = 0;
                
                // Parse the day of the week
                if ([dayString rangeOfString:@"SU"].location != NSNotFound)      dayOfWeek = EKSunday;
                else if ([dayString rangeOfString:@"MO"].location != NSNotFound) dayOfWeek = EKMonday;
                else if ([dayString rangeOfString:@"TU"].location != NSNotFound) dayOfWeek = EKTuesday;
                else if ([dayString rangeOfString:@"WE"].location != NSNotFound) dayOfWeek = EKWednesday;
                else if ([dayString rangeOfString:@"TH"].location != NSNotFound) dayOfWeek = EKThursday;
                else if ([dayString rangeOfString:@"FR"].location != NSNotFound) dayOfWeek = EKFriday;
                else if ([dayString rangeOfString:@"SA"].location != NSNotFound) dayOfWeek = EKSaturday;
                
                // Parse the week number
                weekNumber = [[dayString substringToIndex:dayString.length-2] intValue];
  
                [daysOfTheWeek addObject:[EKRecurrenceDayOfWeek dayOfWeek:dayOfWeek weekNumber:weekNumber]];
            }
        }
        
        // Days of the month
        else if ([component isEqualToString:@"BYMONTHDAY"])
        {
            daysOfTheMonth = [NSMutableArray array];
            NSArray *dayStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *dayString in dayStrings)
            {
                [daysOfTheMonth addObject:[NSNumber numberWithInt:dayString.intValue]];
            }
        }
        
        // Months of the year
        else if ([component isEqualToString:@"BYMONTH"])
        {
            monthsOfTheYear = [NSMutableArray array];
            NSArray *monthStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *monthString in monthStrings)
            {
                [monthsOfTheYear addObject:[NSNumber numberWithInt:monthString.intValue]];
            }
        }
        
        // Weeks of the year
        else if ([component isEqualToString:@"BYWEEKNO"])
        {
            weeksOfTheYear = [NSMutableArray array];
            NSArray *weekStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *weekString in weekStrings)
            {
                [weeksOfTheYear addObject:[NSNumber numberWithInt:weekString.intValue]];
            }
        }
        
        // Days of the year
        else if ([component isEqualToString:@"BYYEARDAY"])
        {
            daysOfTheYear = [NSMutableArray array];
            NSArray *dayStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *dayString in dayStrings)
            {
                [daysOfTheYear addObject:[NSNumber numberWithInt:dayString.intValue]];
            }
        }
        
        // Set positions
        else if ([component isEqualToString:@"BYSETPOS"])
        {
            setPositions = [NSMutableArray array];
            NSArray *positionStrings = [[components objectAtIndex:++i] componentsSeparatedByString:@","];
            for (NSString *potitionString in positionStrings)
            {
                [setPositions addObject:[NSNumber numberWithInt:potitionString.intValue]];
            }
        }
        
        // RecurrenceEnd
        else if ([component isEqualToString:@"COUNT"])
        {
            NSUInteger occurenceCount = [[components objectAtIndex:++i] intValue];
            recurrenceEnd = [EKRecurrenceEnd recurrenceEndWithOccurrenceCount:occurenceCount];
            
        }
        else if ([component isEqualToString:@"UNTIL"])
        {
            NSDate *endDate =  [dateFormatter dateFromString:[components objectAtIndex:++i]];
            recurrenceEnd = [EKRecurrenceEnd recurrenceEndWithEndDate:endDate];
            
            if(more)
                self.endDate = endDate;
        }
        
        // Start Date
        else if ([component isEqualToString:@"DTSTART"])
        {
            NSDate *startDate =  [dateFormatter dateFromString:[components objectAtIndex:++i]];
            
            self.startDate = startDate;
        }
        
    }
    
    return [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:frequency
                                                        interval:interval
                                                   daysOfTheWeek:daysOfTheWeek
                                                  daysOfTheMonth:daysOfTheMonth
                                                 monthsOfTheYear:monthsOfTheYear
                                                  weeksOfTheYear:weeksOfTheYear
                                                   daysOfTheYear:daysOfTheYear
                                                    setPositions:setPositions
                                                             end:recurrenceEnd];
}

- (EKEvent*)eventWithRecurrenceRuleFromString:(NSString*)rfc2445String;
{
    EKRecurrenceRule* newRule = [self initWithString:rfc2445String andParseMore:YES];
    EKEvent* newEvent = [[EKEvent alloc] init];
    [newEvent addRecurrenceRule:newRule];
    newEvent.startDate = self.startDate;
    newEvent.endDate = self.endDate;
    
    return newEvent;
}

@end
