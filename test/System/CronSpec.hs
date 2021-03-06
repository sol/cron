{-# LANGUAGE OverloadedStrings #-}
module System.CronSpec (spec) where

import Data.Time.Clock
import Data.Time.Calendar
import Data.Time.LocalTime
import Test.Hspec

import System.Cron

spec :: Spec
spec = sequence_ [describeScheduleMatches,
                  describeCronScheduleShow,
                  describeCrontabEntryShow,
                  describeCrontabShow ]

---- Specs
describeScheduleMatches :: Spec
describeScheduleMatches = describe "ScheduleMatches" $ do
  it "matches a catch-all" $
    scheduleMatches stars (day 5 25 1 2)

  it "matches a specific field" $
    scheduleMatches stars { hour = Hours (SpecificField 1)}
                    (day 5 25 1 2)

  it "matches a range" $
    scheduleMatches stars { dayOfMonth = DaysOfMonth (RangeField 3 5)}
                    (day 5 4 1 2)

  it "does not match invalid range" $
    not $ scheduleMatches stars { dayOfMonth = DaysOfMonth (RangeField 5 3)}
                          (day 5 4 1 2)

  it "matches a list" $
    scheduleMatches stars { month = Months (ListField [SpecificField 1,
                                                       SpecificField 2,
                                                       SpecificField 3])}
                    (day 2 3 1 2)
  it "matches a step field" $
     scheduleMatches stars { dayOfMonth = DaysOfMonth (StepField (RangeField 10 16) 2)}
                     (day 5 12 1 2)
  it "does not match something missing the step field" $
    not $ scheduleMatches stars { dayOfMonth = DaysOfMonth (StepField (RangeField 10 16) 2)}
                          (day 5 13 1 2)

  it "matches starred stepped fields" $
    scheduleMatches stars { minute = Minutes (StepField Star 2)}
                          (day 5 13 1 4)

  it "does not match fields that miss starred stepped fields" $
    not $ scheduleMatches stars { minute = Minutes (StepField Star 2)}
                          (day 5 13 1 5)

  it "matches multiple fields at once" $
    scheduleMatches stars { minute     = Minutes (StepField Star 2),
                            dayOfMonth = DaysOfMonth (SpecificField 3),
                            hour       = Hours (RangeField 10 14) }
                    (day 5 3 13 2)
  where day m d h mn = UTCTime (fromGregorian 2012 m d) (diffTime h mn)
        diffTime h mn = timeOfDayToTime $ TimeOfDay h mn 0

describeCronScheduleShow :: Spec
describeCronScheduleShow = describe "CronSchedule show" $ do
  it "formats stars" $
    show stars `shouldBe`
         "CronSchedule * * * * *"

  it "formats specific numbers" $
    show stars { dayOfWeek = DaysOfWeek (SpecificField 3)} `shouldBe`
         "CronSchedule * * * * 3"

  it "formats lists" $
    show stars { minute = Minutes (ListField [SpecificField 1,
                                   SpecificField 2,
                                   SpecificField 3])} `shouldBe`
         "CronSchedule 1,2,3 * * * *"

  it "formats ranges" $
    show stars { hour = Hours (RangeField 7 10)} `shouldBe`
         "CronSchedule * 7-10 * * *"

  it "formats steps" $
    show stars { dayOfMonth = DaysOfMonth (StepField (ListField [SpecificField 3, SpecificField 5]) 2)} `shouldBe`
         "CronSchedule * * 3,5/2 * *"

describeCrontabShow :: Spec
describeCrontabShow = describe "Crontab Show" $ do
  it "prints nothing for an empty crontab" $
    show (Crontab []) `shouldBe` ""

describeCrontabEntryShow :: Spec
describeCrontabEntryShow = describe "CrontabEntry Show" $ do
  it "formats environment variable sets" $
    show envSet `shouldBe` "FOO=BAR"

  it "formats command entries" $
    show entry `shouldBe` "* * * * * do stuff"


envSet :: CrontabEntry
envSet = EnvVariable "FOO" "BAR"

entry :: CrontabEntry
entry = CommandEntry stars "do stuff"

stars :: CronSchedule
stars = CronSchedule (Minutes Star)
                     (Hours Star)
                     (DaysOfMonth Star)
                     (Months Star)
                     (DaysOfWeek Star)
