## START #########################################################################################

com.xceptance.xlt.mastercontroller.testSuitePath = /Users/ext.maarten.vanderho/dev/xlt-4.13.0/flaconi
com.xceptance.xlt.mastercontroller.ui.status.detailedList = false
com.xceptance.xlt.mastercontroller.ui.status.updateInterval = 5
com.xceptance.xlt.mastercontroller.password = ${password}

com.xceptance.xlt.mastercontroller.https.proxy.enabled = false
com.xceptance.xlt.mastercontroller.https.proxy.host =
com.xceptance.xlt.mastercontroller.https.proxy.port =
com.xceptance.xlt.mastercontroller.https.proxy.bypassForHosts =
${agentcontrollerblock}

log4j.rootLogger = warn, file
log4j.logger.com.xceptance = warn
log4j.logger.runtime = warn

log4j.appender.console = org.apache.log4j.ConsoleAppender
log4j.appender.console.layout = org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern = [%d{HH:mm:ss,SSS}] %-5p [%t] - %m%n

log4j.appender.file = org.apache.log4j.RollingFileAppender
log4j.appender.file.File = $${com.xceptance.xlt.home}/log/mastercontroller.log
log4j.appender.file.MaxFileSize = 10MB
log4j.appender.file.MaxBackupIndex = 10
log4j.appender.file.layout = org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern = [%d{yyyy/MM/dd-HH:mm:ss,SSS}] %-5p [%t] %c - %m%n

## END  ##########################################################################################
