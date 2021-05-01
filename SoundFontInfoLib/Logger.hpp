// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>

#include <memory>
#include <sstream>
#include <string>

namespace SF2 {

/**
 Light wrapper around a os_log_t value that provides for building log message content via '<<' operators.

 Example: log_.debug() << "the value " << foo << " is invalid" << std::endl;

 The buffer continues to accumulate data until the `std::endl` manipulator at which point the buffer sends its contents
 to os_log and resets. Note that the end result is always emitted via a "%{public}s" format so care should be taken to
 not leak any personal info.
 */
struct Logger {

    /// Base name to use for all os_log subsystem names.
    inline static const std::string base{"com.braysoft.SoundFontInfoLib.SF2."};

    /**
     Create a new os_log_t instance.

     @param subsystem the subsystem name to use. This will be appended to `base`.
     @param category the category to use
     @returns new/existing os_log_ instance
     */
    static Logger Make(const std::string& subsystem, const std::string& category) {
        return Logger(os_log_create((base + subsystem).c_str(), category.c_str()));
    }

    /**
     Allow Logger instances to appear in os_log API calls.
     @returns internal os_log_t value
     */
    operator os_log_t() const { return log_; }

    /// @returns stream to use for debug-level messages (NOTE: streams are not thread-safe)
    std::ostream& debug() { return getStream(OS_LOG_TYPE_DEBUG); }

    /// @returns stream to use for info-level messages (NOTE: streams are not thread-safe)
    std::ostream& info() { return getStream(OS_LOG_TYPE_INFO); }

    /// @returns stream to use for error-level messages (NOTE: streams are not thread-safe)
    std::ostream& error() { return getStream(OS_LOG_TYPE_ERROR); }

    /// @returns stream to use for fault-level messages (NOTE: streams are not thread-safe)
    std::ostream& fault() { return getStream(OS_LOG_TYPE_FAULT); }

private:

    Logger(os_log_t log) :
    log_{log},
    lsb_(new LogStreamBuf(log_)),
    os_(new std::ostream(lsb_.get())),
    null_(new std::ostream(new NullLogStreamBuf))
    {
        // Flag the 'null' stream as being bad so that '<<' will decide to not write to it.
        null_->setstate(std::ios_base::badbit);
    }

    /**
     Stream buffer that accumulates a log line until it is told to "sync" via `std::endl` manipulator at which time it
     sends a string to os_log with at the appropriate level.
     */
    struct LogStreamBuf : public std::stringbuf {
        LogStreamBuf(os_log_t log) : std::stringbuf(std::ios_base::out), log_(log) {}

        void setLevel(os_log_type_t level) { level_ = level; }

        int sync() {
            int rc = std::stringbuf::sync();
            os_log_with_type(log_, level_, "%{public}s", str().c_str());
            str("");
            return rc;
        }

        os_log_t log_;
        os_log_type_t level_;
    };

    /**
     Stream buffer used for loggers that are not enabled. Does not accumulate any data, and if the
     */
    struct NullLogStreamBuf : public std::stringbuf {
        NullLogStreamBuf() : std::stringbuf(std::ios_base::out) {}
        std::streamsize xsputn(const char_type* s, std::streamsize n) { return n; }
    };

    /**
     Obtain the stream to write to based on the given log level activation.

     @param level the log level to use
     @returns output stream
     */
    std::ostream& getStream(os_log_type_t level) {
        if (!os_log_type_enabled(log_, level)) return *null_;
        lsb_->setLevel(level);
        return *os_;
    }

    os_log_t log_;
    std::unique_ptr<LogStreamBuf> lsb_;
    std::unique_ptr<std::ostream> os_;
    std::unique_ptr<std::ostream> null_;
};

} // end namespace SF2
