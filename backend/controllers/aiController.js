const { spawn } = require('child_process');
const path = require('path');

const predictSite = (req, res) => {
    console.log('\n========================================');
    console.log('AI PREDICTION REQUEST');
    console.log('Content-Type:', req.headers['content-type']);
    console.log('Body:', req.body);
    console.log('========================================');

    if (!req.body || typeof req.body !== 'object') {
        return res.status(400).json({
            success: false,
            error: 'Request body is missing or invalid JSON.'
        });
    }

    const pythonExecutable =
        process.env.PYTHON_PATH || '/opt/anaconda3/bin/python';

    const predictorPath = path.join(
        __dirname,
        '..',
        'ml',
        'predictor.py'
    );

    console.log('Python:', pythonExecutable);
    console.log('Predictor:', predictorPath);

    const pythonProcess = spawn(
        pythonExecutable,
        [predictorPath, '--stdin'],
        {
            cwd: path.join(__dirname, '..'),
            stdio: ['pipe', 'pipe', 'pipe']
        }
    );

    let stdout = '';
    let stderr = '';

    pythonProcess.stdout.setEncoding('utf8');
    pythonProcess.stderr.setEncoding('utf8');

    pythonProcess.stdout.on('data', (data) => {
        stdout += data;
    });

    pythonProcess.stderr.on('data', (data) => {
        stderr += data;
    });

    pythonProcess.on('error', (error) => {
        console.error('PYTHON PROCESS ERROR:', error);

        if (!res.headersSent) {
            return res.status(500).json({
                success: false,
                error: `Failed to start Python: ${error.message}`
            });
        }
    });

    pythonProcess.on('close', (code) => {
        console.log('Python exit code:', code);

        if (stderr) {
            console.log('Python stderr:');
            console.log(stderr);
        }

        console.log('Python stdout:');
        console.log(stdout);

        if (code !== 0) {
            return res.status(500).json({
                success: false,
                error: stderr || `Python exited with code ${code}`
            });
        }

        const cleanOutput = stdout.trim();

        if (!cleanOutput) {
            return res.status(500).json({
                success: false,
                error: 'Python returned empty output.'
            });
        }

        try {
            const result = JSON.parse(cleanOutput);

            if (result.error) {
                return res.status(500).json({
                    success: false,
                    error: result.error
                });
            }

            return res.status(200).json({
                success: true,
                prediction: result
            });

        } catch (error) {
            console.error('JSON parsing error:', error);

            return res.status(500).json({
                success: false,
                error: 'Python returned invalid JSON.',
                raw_output: cleanOutput
            });
        }
    });

    const input = JSON.stringify(req.body);

    console.log('Sending to Python:');
    console.log(input);

    if (!pythonProcess.stdin) {
        console.error('Python stdin is undefined.');

        return res.status(500).json({
            success: false,
            error: 'Python stdin pipe was not created.'
        });
    }

    pythonProcess.stdin.write(input, 'utf8');
    pythonProcess.stdin.end();
};

module.exports = {
    predictSite
};
