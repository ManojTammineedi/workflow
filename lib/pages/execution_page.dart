import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:workflow/Notifiers/task_notifier.dart';
import 'package:workflow/models/task.dart';

class WorkflowExecutionPage extends ConsumerStatefulWidget {
  final int workflowId;
  final String workflowName;

  WorkflowExecutionPage({required this.workflowId, required this.workflowName});

  @override
  _WorkflowExecutionPageState createState() => _WorkflowExecutionPageState();
}

class _WorkflowExecutionPageState extends ConsumerState<WorkflowExecutionPage> {
  late List<Task> tasks;
  int currentTaskIndex = 0;
  bool isRunning = false;
  bool isPaused = false;
  late Timer _timer;
  List<String> executionLog = [];
  double progress = 0.0;
  int remainingTime = 0;
  int originalDelay = 0;

  @override
  void initState() {
    super.initState();
    tasks = ref.read(taskProvider(widget.workflowId)); // Retrieve tasks
    print('Tasks loaded: ${tasks.length}');
  }

  void _startExecution() {
    setState(() {
      isRunning = true;
      isPaused = false;
      currentTaskIndex = 0;
      executionLog.clear();
      progress = 0.0;
      remainingTime = 0; // Reset remaining time at start
    });
    print('Starting execution...');
    _executeTask();
  }

  void _pauseExecution() {
    setState(() {
      isPaused = true;
    });
    if (_timer.isActive) {
      _timer.cancel(); // Stop the timer without resetting remaining time
    }
    print('Execution paused');
  }

  void _resumeExecution() {
    setState(() {
      isPaused = false;
    });
    print('Resuming execution...');

    // Resume the delay task if it's currently a delay task
    if (tasks[currentTaskIndex].type == 'Delay') {
      _executeDelay(tasks[currentTaskIndex]);
    } else {
      _executeTask(); // Continue executing other tasks if not a delay
    }
  }

  void _executeTask() {
    if (currentTaskIndex >= tasks.length) {
      setState(() {
        isRunning = false;
        progress = 1.0;
      });
      print('All tasks completed');
      return;
    }

    final task = tasks[currentTaskIndex];
    print('Executing task: ${task.title}');
    setState(() {
      executionLog.add('Running: ${task.title}');
    });

    if (task.type == 'Computation') {
      _executeComputation(task);
    } else if (task.type == 'Delay') {
      _executeDelay(task);
    } else if (task.type == 'Decision') {
      _executeDecision(task);
    }
  }

  void _executeDelay(Task task) {
    final delay = int.tryParse(task.parameters ?? '0') ?? 0;

    // If remainingTime is already set, it means the task was paused, so we resume from there
    if (remainingTime == 0) {
      remainingTime = delay; // Set remaining time on first execution
      originalDelay = delay; // Store the original delay to calculate progress
    }

    print('Starting delay task with remainingTime: $remainingTime');

    // Start the timer if it's the first time running or if remainingTime was reset
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isPaused) {
        print('Timer paused at: $remainingTime seconds remaining');
        timer.cancel();
        return; // Stop the timer if paused
      }

      setState(() {
        executionLog.add('Waiting: $remainingTime seconds remaining');
        progress = (originalDelay - remainingTime + 1) /
            originalDelay; // Calculate progress based on original delay
        remainingTime--;
      });

      if (remainingTime <= 0) {
        print('Delay task completed');
        timer.cancel();
        _moveToNextTask(); // Move to the next task when done
      }
    });
  }

  void _executeComputation(Task task) {
    final result = _performComputation(task.parameters ?? '');
    setState(() {
      executionLog.add('Completed: ${task.title} - Result: $result');
    });
    print('Computation completed: ${task.title}, Result: $result');
    _moveToNextTask();
  }

  dynamic _performComputation(String operation) {
    try {
      // Check for time-based expressions like "7:00AM + 10min"
      final timePattern =
          RegExp(r"(\d{1,2}:\d{2}[APMapm]{2})\s*([+-])\s*(\d+)([a-zA-Z]+)");
      final match = timePattern.firstMatch(operation);

      if (match != null) {
        // Extract the components of the time-based operation
        final timeString = match.group(1)!;
        final operator = match.group(2)!;
        final durationValue = int.parse(match.group(3)!);
        final durationUnit = match.group(4)!;

        DateTime time = _parseTime(timeString);

        // Perform the operation based on the operator
        if (operator == '+') {
          time = _addDuration(time, durationValue, durationUnit);
        } else if (operator == '-') {
          time = _subtractDuration(time, durationValue, durationUnit);
        }

        // Return the result in a human-readable format
        return _formatTime(time);
      } else {
        // Handle arithmetic operations (e.g., "7 + 10")
        final parts = operation.split(' ');
        if (parts.length == 3) {
          final operand1 = double.parse(parts[0]);
          final operand2 = double.parse(parts[2]);

          switch (parts[1]) {
            case '+':
              return operand1 + operand2;
            case '-':
              return operand1 - operand2;
            case '*':
              return operand1 * operand2;
            case '/':
              return operand1 / operand2;
            default:
              throw 'Invalid operation';
          }
        }
        throw 'Invalid format';
      }
    } catch (e) {
      print('Error in computation: $e');
      return 'Error';
    }
  }

  DateTime _parseTime(String timeString) {
    // Normalize the time string (remove spaces between time and AM/PM)
    timeString = timeString.replaceAll(' ', '');
    final timeFormat =
        DateFormat('h:mma'); // Remove space for parsing like "7:00AM"

    try {
      return timeFormat.parse(timeString);
    } catch (e) {
      throw 'Invalid time format';
    }
  }

  DateTime _addDuration(DateTime time, int value, String unit) {
    switch (unit.toLowerCase()) {
      case 'min':
      case 'minute':
      case 'minutes':
        return time.add(Duration(minutes: value));
      case 'hr':
      case 'hour':
      case 'hours':
        return time.add(Duration(hours: value));
      case 'sec':
      case 'second':
      case 'seconds':
        return time.add(Duration(seconds: value));
      default:
        throw 'Unknown time unit';
    }
  }

  DateTime _subtractDuration(DateTime time, int value, String unit) {
    switch (unit.toLowerCase()) {
      case 'min':
      case 'minute':
      case 'minutes':
        return time.subtract(Duration(minutes: value));
      case 'hr':
      case 'hour':
      case 'hours':
        return time.subtract(Duration(hours: value));
      case 'sec':
      case 'second':
      case 'seconds':
        return time.subtract(Duration(seconds: value));
      default:
        throw 'Unknown time unit';
    }
  }

  String _formatTime(DateTime time) {
    final timeFormat = DateFormat('h:mm a');
    return timeFormat.format(time);
  }

  void _executeDecision(Task task) {
    final condition = task.parameters ?? '';
    final recondition = condition.toLowerCase();
    print('Decision condition: $recondition');

    // Manually search for 'if' and 'else' in the statement
    if (!recondition.contains('if') || !recondition.contains('else')) {
      setState(() {
        executionLog.add('Invalid decision format for "${task.title}".');
        print('Invalid decision format for "${task.title}".');
      });
      _moveToNextTask();
      return;
    }

    // Find the index of 'if' and 'else'
    final ifIndex = recondition.indexOf('if');
    final elseIndex = recondition.indexOf('else');

    // Extract the condition, ifAction, and elseAction
    final variableCondition =
        recondition.substring(ifIndex + 2, recondition.indexOf(',')).trim();
    final ifAction =
        recondition.substring(recondition.indexOf(',') + 1, elseIndex).trim();
    final elseAction = recondition
        .substring(elseIndex + 4, recondition.length)
        .replaceAll('.', '')
        .trim();

    if (variableCondition.isEmpty || ifAction.isEmpty || elseAction.isEmpty) {
      setState(() {
        executionLog.add('Error parsing decision for "${task.title}".');
      });
      _moveToNextTask();
      return;
    }

    // Show a dialog to let the user select the branch
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Decision for "${task.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Condition: $variableCondition'),
              SizedBox(height: 10),
              Text('Please select an action:'),
              SizedBox(height: 20),
              // Buttons for selecting the branch
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    executionLog
                        .add('Decision result for "${task.title}": $ifAction');
                  });
                  Navigator.of(context).pop();
                  _moveToNextTask(); // Move to next task after selection
                },
                child: Text(ifAction),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    executionLog.add(
                        'Decision result for "${task.title}": $elseAction');
                  });
                  Navigator.of(context).pop();
                  _moveToNextTask(); // Move to next task after selection
                },
                child: Text(elseAction),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _evaluateCondition(String condition, double input) {
    try {
      final parts = condition.split(' ');
      if (parts.length == 3) {
        final variable = input;
        final operator = parts[1];
        final value = double.parse(parts[2]);

        switch (operator) {
          case '>':
            return variable > value;
          case '<':
            return variable < value;
          case '==':
            return variable == value;
          case '>=':
            return variable >= value;
          case '<=':
            return variable <= value;
          default:
            throw 'Invalid operator';
        }
      }
      throw 'Invalid condition format';
    } catch (e) {
      print('Error in condition evaluation: $e');
      return false;
    }
  }

  void _moveToNextTask() {
    setState(() {
      currentTaskIndex++;
      remainingTime = 0;
    });
    print('Moving to next task: $currentTaskIndex');
    if (isRunning && !isPaused) {
      _executeTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('${widget.workflowName} Execution'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: progress),
            SizedBox(height: 10),
            Text('Executing Tasks:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (ctx, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(task.title),
                    subtitle: Text(task.type),
                    tileColor: index == currentTaskIndex
                        ? Colors.blue.shade100
                        : Colors.transparent,
                    leading: CircleAvatar(
                      backgroundColor:
                          index == currentTaskIndex ? Colors.blue : Colors.grey,
                      child: Text((index + 1).toString()),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Execution Log:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: executionLog.length,
                itemBuilder: (ctx, index) {
                  return ListTile(
                    title: Text(executionLog[index]),
                  );
                },
              ),
            ),
            if (!isRunning)
              Container(
                padding: EdgeInsets.all(16),
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.black),
                  ),
                  onPressed: _startExecution,
                  child: Text(
                    'Start Execution',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            if (isRunning)
              isPaused
                  ? Container(
                      padding: EdgeInsets.all(16),
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.black),
                        ),
                        onPressed: _resumeExecution,
                        child: Text('Resume Execution',
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.all(16),
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.black),
                        ),
                        onPressed: _pauseExecution,
                        child: Text('Pause Execution',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
