var aws  = require('aws-sdk');
var zlib = require('zlib');
var async = require('async');

var EVENT_SOURCE_TO_TRACK = /rds.amazonaws.com/;
var DST_BUCKET = process.env.DST_BUCKET;

var s3 = new aws.S3();

exports.handler = function(event, context, callback) {
    console.log('Received Event: ' + JSON.stringify(event));

    var srcBucket = event.Records[0].s3.bucket.name;
    var srcKey = event.Records[0].s3.object.key;

    async.waterfall([
        function fetchLogFromS3(next){
            console.log('Fetching compressed log from S3...');
            s3.getObject({
               Bucket: srcBucket,
               Key: srcKey
            },
            next);
        },
        function uncompressLog(response, next){
            console.log("Uncompressing log...");
            zlib.gunzip(response.Body, next);
        },
        function filterRecords(jsonBuffer, next) {
            console.log('Filtering log...');
            var json = jsonBuffer.toString();
            console.log('CloudTrail JSON from S3:', json);
            var records;
            try {
                records = JSON.parse(json);
            } catch (err) {
                next('Unable to parse CloudTrail JSON: ' + err);
                return;
            }
            var matchingRecords = records
                .Records
                .filter(function(record) {
                    return record.eventSource.match(EVENT_SOURCE_TO_TRACK);
                });

            if (matchingRecords.length == 0) {
                console.log('No matching record(s) with "eventSource": "' + EVENT_SOURCE_TO_TRACK + '" found. Terminating...')
                callback(null, 'No matching records');
            }
            else {
                console.log('Total ' + matchingRecords.length + ' record(s) with "eventSource": "' + EVENT_SOURCE_TO_TRACK + '" found');
                console.log('Compressing Log...');
                zlib.gzip(Buffer.from(JSON.stringify(matchingRecords), 'utf-8'), next);
            }
        },
        function copyToDstBucket(buffer, next) {
            console.log('Copying record(s) to destination bucket:' + DST_BUCKET);
            s3.upload({
                Bucket: DST_BUCKET,
                Key: srcKey,
                Body: buffer
            },
            next);
        }
    ], function (err) {
        if (err) {
            console.error('Failed to copy filtered record(s): ', err);
        } else {
            console.log('Successfully copied all filtered record(s) to s3://' + DST_BUCKET + '/' + srcKey);
        }
        callback(null, 'Ok');
    });
};