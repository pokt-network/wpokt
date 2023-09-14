const execSync = require("child_process").execSync;

const runWithResult = (cmd) => {
  try {
    const result = execSync(cmd, { encoding: "utf-8" });
    return {
      success: true,
      error: null,
      result,
    };
  } catch (e) {
    return {
      success: false,
      error: e.message,
      result: null,
    };
  }
};

const run = (cmd) => {
  try {
    execSync(cmd, { encoding: "utf-8", stdio: "inherit" });
    return {
      success: true,
      error: null,
    };
  } catch (e) {
    return {
      success: false,
      error: e.message,
    };
  }
};

module.exports = {
  run,
  runWithResult,
};
