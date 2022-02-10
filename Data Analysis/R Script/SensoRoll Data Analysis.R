VDATA <- read.csv("F:\\University of Trento\\Human-Computer Interaction\\3rd Semester\\Multisensory Interactive Systems\\Project\\Data Set\\Results of Game Modes\\Visual Mode Spliced.csv")
AHDATA <- read.csv("F:\\University of Trento\\Human-Computer Interaction\\3rd Semester\\Multisensory Interactive Systems\\Project\\Data Set\\Results of Game Modes\\AudioHaptics Mode Spliced.csv")
QDATA <- read.csv("F:\\University of Trento\\Human-Computer Interaction\\3rd Semester\\Multisensory Interactive Systems\\Project\\Data Set\\Results of Questionnaire\\MIS Questionnaire Spliced.csv")


head(VDATA)
head(AHDATA)
head(QDATA)

summary(VDATA)
summary(AHDATA)
summary(QDATA)

summary(VDATA[,2])
summary(VDATA[,6])
summary(VDATA[,10])

summary(AHDATA[,2])
summary(AHDATA[,6])
summary(AHDATA[,10])




# Computing Descriptive statistics on Behaviorial data in Visual mode and Auditory/Haptics mode

VMeanPerformance <- mean(VDATA$totalGameTime2)
VSdPerformance <- sd(VDATA$totalGameTime2)
VMeanLearnability <- mean(VDATA$totalGameTimeDifference)
VSdLearnability <- sd(VDATA$totalGameTimeDifference)
VSummaryPerformance <- summary(VDATA$totalGameTime2)


AHMeanPerformance <- mean(AHDATA$totalGameTime2)
AHSdPerformance <- sd(AHDATA$totalGameTime2)
AHMeanLearnability <- mean(AHDATA$totalGameTimeDifference)
AHSdLearnability <- sd(AHDATA$totalGameTimeDifference)
AHSummaryPerformance <- summary(AHDATA$totalGameTime2)


VMeanPerformance
VSdPerformance
VMeanLearnability
VSdLearnability
VSummaryPerformance


AHMeanPerformance
AHSdPerformance
AHMeanLearnability
AHSdLearnability
AHSummaryPerformance



#Computing Inferential statistics on Behaviorial data in Visual mode and Auditory/Haptics mode

t.test((VDATA$totalGameTime2),(AHDATA$totalGameTime2),paired=TRUE)
t.test((VDATA$totalGameTimeDifference),(AHDATA$totalGameTimeDifference),paired=TRUE)




# Computing Descriptive statistics on Demographic data of participants


Gender <- as.factor(QDATA$Gender)
Gender
table(Gender)

Age <- factor(QDATA$Age,levels=c("18-22","23-26","27-30","30+"),ordered=TRUE)
Age
table(Age)
barplot(table(Age),xlab="Age Ranges of Participants",ylab="Frequency",col="coral")


GamingExpSummary <- summary(QDATA$GamingExp)
GamingExpMean <- mean(QDATA$GamingExp)
GamingExpSd <- sd(QDATA$GamingExp)
GamingExpSummary
GamingExpMean
GamingExpSd




# Computing Correlation between Gaming Experience of participants and the Performance & Learnability in Visual mode & Auditory/Haptics mode


cor(QDATA$GamingExp,VDATA$totalGameTime2)
cor(QDATA$GamingExp,AHDATA$totalGameTime2)
cor(QDATA$GamingExp,VDATA$totalGameTimeDifference)
cor(QDATA$GamingExp,AHDATA$totalGameTimeDifference)

# No considerable correlations between Gaming Experience and Performance/Learnability
# However, we still can see the level of correlation between Gaming Exp and performance on AH is higher than that of V 



# Computing Descriptive statistics for Subjective data (Answers to questions about the system)

VMeanScores <- apply(QDATA[,5:9],2,mean)
AHMeanScores <- apply(QDATA[,10:14],2,mean)
VSdScores <- apply(QDATA[,5:9],2,sd)
AHSdScores <- apply(QDATA[,10:14],2,sd)

VMeanScores
AHMeanScores
VSdScores
AHSdScores



# Computing Correlation between Performance and Subjective data (Answers to questions about the system) in Auditory/Haptics mode

cor(VDATA$totalGameTime2, QDATA[,5:9])
cor(AHDATA$totalGameTime2, QDATA[,10:14])


# For the Visual mode, there is a weak or very weak correlation between Performance and Subjective data about each game task perceived difficulty.
# It means that the design of the game elements did not have a considerable impact on the performance of the Participants playing in the Visual mode.

# For the Audio/Haptics mode, there is a Medium correlation (in negative direction) between Performance and Subjective data about each game task perceived difficulty.
# This means that when the design of the game elements did have a Medium impact (not negligible) on the performance of the Participants playing in the Audio/Haptics mode.
# In other words, when each of game tasks is accomplished with greater difficulty (lower score), the participants show lower performace (more time to complete the track).





# Computing Inferential statistics for Subjective data (Answers to questions about the system)


t.test((QDATA[,5]),(QDATA[,10]), paired=TRUE)
t.test((QDATA[,6]),(QDATA[,11]), paired=TRUE)
t.test((QDATA[,7]),(QDATA[,12]), paired=TRUE)
t.test((QDATA[,8]),(QDATA[,13]), paired=TRUE)
t.test((QDATA[,9]),(QDATA[,14]), paired=TRUE)




# Performing Correlation test between Performance and Subjective data (Answers to questions about the system) in Auditory/Haptics mode


cor.test(AHDATA$totalGameTime2, QDATA[,10])
cor.test(AHDATA$totalGameTime2, QDATA[,11])
cor.test(AHDATA$totalGameTime2, QDATA[,12])
cor.test(AHDATA$totalGameTime2, QDATA[,13])
cor.test(AHDATA$totalGameTime2, QDATA[,14])

# Tests on the statistical significance of the correlation results show that only three of the results can be extended to the larger population of users (OrientOnTrack, WallLocate, WallAvoidance),
# while the other two cannot, because their p-value do not reach the 0.05 threshold (StayOnTrack, WallDistinction).

