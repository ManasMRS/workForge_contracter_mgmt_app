const { spawn } = require('child_process');
const path = require('path');

const predictSite = (req, res) => {
    console.log('\n========================================');
    console.log('AI PREDICTION REQUEST');
    console.log('Content-Type:', req.headers['content-type']);
    console.log('Body:', req.body);
    console.log('========================================');

    // =========================================================
    // VALIDATE REQUEST
    // =========================================================

    if (!req.body || typeof req.body !== 'object') {
        return res.status(400).json({
            success: false,
            error: 'Request body is missing or invalid JSON.'
        });
    }

    // =========================================================
    // PYTHON CONFIGURATION
    // =========================================================

    const pythonExecutable =
        process.env.PYTHON_PATH || 'python3';

    const backendDirectory = path.join(
        __dirname,
        '..'
    );

    const predictorPath = path.join(
        backendDirectory,
        'ml',
        'predictor.py'
    );

    console.log('Python executable:', pythonExecutable);
    console.log('Python predictor:', predictorPath);
    console.log('Working directory:', backendDirectory);

    // =========================================================
    // START PYTHON
    // =========================================================

    const pythonProcess = spawn(
        pythonExecutable,
        [
            predictorPath,
            '--stdin'
        ],
        {
            cwd: backendDirectory,

            env: {
                ...process.env,

                // Prevent Python from buffering stdout.
                PYTHONUNBUFFERED: '1'
            },

            stdio: [
                'pipe',
                'pipe',
                'pipe'
            ]
        }
    );

    let stdout = '';
    let stderr = '';

    // =========================================================
    // PYTHON STDOUT
    // =========================================================

    pythonProcess.stdout.setEncoding('utf8');

    pythonProcess.stdout.on(
        'data',
        (data) => {
            stdout += data.toString();
        }
    );

    // =========================================================
    // PYTHON STDERR
    // =========================================================

    pythonProcess.stderr.setEncoding('utf8');

    pythonProcess.stderr.on(
        'data',
        (data) => {
            stderr += data.toString();
        }
    );

    // =========================================================
    // PYTHON START ERROR
    // =========================================================

    pythonProcess.on(
        'error',
        (error) => {

            console.error(
                'PYTHON PROCESS START ERROR:',
                error
            );

            if (!res.headersSent) {

                return res.status(500).json({
                    success: false,
                    error:
                        `Failed to start Python: ${error.message}`
                });
            }
        }
    );

    // =========================================================
    // PYTHON PROCESS CLOSED
    // =========================================================

    pythonProcess.on(
        'close',
        (code, signal) => {

            console.log(
                'Python exit code:',
                code
            );

            console.log(
                'Python signal:',
                signal
            );

            console.log(
                'Python stdout:',
                stdout
            );

            if (stderr.trim()) {

                console.log(
                    'Python stderr:',
                    stderr
                );
            }

            // =====================================================
            // PYTHON FAILED
            // =====================================================

            if (code !== 0) {

                let errorMessage =
                    stderr.trim();

                if (!errorMessage) {

                    errorMessage =
                        `Python exited with code ${code}`;
                }

                return res.status(500).json({
                    success: false,
                    error: errorMessage,

                    python_exit_code: code,

                    python_signal: signal,

                    stdout: stdout.trim()
                });
            }

            // =====================================================
            // EMPTY OUTPUT
            // =====================================================

            const cleanOutput =
                stdout.trim();

            if (!cleanOutput) {

                return res.status(500).json({
                    success: false,
                    error:
                        'Python returned empty output.',

                    python_stderr:
                        stderr.trim()
                });
            }

            // =====================================================
            // PARSE JSON
            // =====================================================

            let result;

            try {

                result =
                    JSON.parse(cleanOutput);

            } catch (error) {

                console.error(
                    'Python JSON parsing error:',
                    error
                );

                return res.status(500).json({
                    success: false,

                    error:
                        'Python returned invalid JSON.',

                    raw_output:
                        cleanOutput,

                    python_stderr:
                        stderr.trim()
                });
            }

            // =====================================================
            // PYTHON RETURNED APPLICATION ERROR
            // =====================================================

            if (
                result &&
                result.error
            ) {

                return res.status(500).json({
                    success: false,

                    error:
                        result.error,

                    python_stderr:
                        stderr.trim()
                });
            }

            // =====================================================
            // SUCCESS
            // =====================================================

            return res.status(200).json({

                success: true,

                prediction: result,

                // stderr can contain warnings.
                // It is NOT treated as an error when
                // Python exits successfully.
                warning:
                    stderr.trim() || null
            });
        }
    );

    // =========================================================
    // SEND REQUEST DATA TO PYTHON
    // =========================================================

    const input =
        JSON.stringify(req.body);

    console.log(
        'Sending JSON to Python:'
    );

    console.log(input);

    // =========================================================
    // CHECK STDIN
    // =========================================================

    if (!pythonProcess.stdin) {

        console.error(
            'Python stdin is undefined.'
        );

        return res.status(500).json({
            success: false,
            error:
                'Python stdin pipe was not created.'
        });
    }

    // =========================================================
    // SEND JSON
    // =========================================================

    pythonProcess.stdin.write(
        input,
        'utf8'
    );

    pythonProcess.stdin.end();
};


module.exports = {
    predictSite
};