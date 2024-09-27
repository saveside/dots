#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/stat.h>

#define LOG_FILE "/var/tmp/update.log"
#define LOCK_FILE "/var/tmp/update.lock"
#define MIRROR_LOCK_FILE "/var/tmp/mirror.lock"
#define COMMAND_SIZE 256

const char *managers[] = {"yay", "paru", "pacman"};

bool run_command(const char *command, FILE *log_fp)
{
  int pipe_fd[2];
  if (pipe(pipe_fd) == -1)
  {
    perror("pipe");
    return false;
  }

  pid_t pid = fork();
  if (pid == -1)
  {
    perror("fork");
    return false;
  }

  if (pid == 0)
  {
    close(pipe_fd[0]);
    dup2(pipe_fd[1], STDOUT_FILENO);
    dup2(pipe_fd[1], STDERR_FILENO);
    close(pipe_fd[1]);

    char *const argv[] = {"/usr/bin/bash", "-c", (char *)command, NULL};
    execvp("/usr/bin/bash", argv);
    _exit(EXIT_FAILURE);
  }
  else
  {
    close(pipe_fd[1]);

    char buffer[COMMAND_SIZE];
    ssize_t bytes_read;

    while ((bytes_read = read(pipe_fd[0], buffer, sizeof(buffer) - 1)) > 0)
    {
      buffer[bytes_read] = '\0';
      fputs(buffer, log_fp);
      fflush(log_fp);
    }

    close(pipe_fd[0]);

    int status;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
  }
}

bool create_lock_file(const char *lock_file)
{
  int lock_fd = open(lock_file, O_CREAT | O_EXCL, 0600);
  if (lock_fd == -1)
  {
    perror("lock file");
    return false;
  }
  close(lock_fd);
  return true;
}

int main()
{
  if (geteuid() != 0)
  {
    fprintf(stderr, "This script requires root privileges.\n");
    return EXIT_FAILURE;
  }

  if (!create_lock_file(LOCK_FILE))
  {
    fprintf(stderr, "Another instance of the script is running.\n");
    return EXIT_FAILURE;
  }

  struct stat buffer;
  if (stat(MIRROR_LOCK_FILE, &buffer) == 0)
  {
    fprintf(stderr, "Mirror update is in progress. Cannot proceed with updates.\n");
    return EXIT_FAILURE;
  }

  FILE *log_fp = fopen(LOG_FILE, "w");
  if (!log_fp)
  {
    perror("fopen");
    remove(LOCK_FILE);
    return EXIT_FAILURE;
  }

  bool update_success = false;
  for (size_t i = 0; i < (sizeof(managers) / sizeof(managers[0])); ++i)
  {
    char command[COMMAND_SIZE];
    snprintf(command, sizeof(command), "%s -Syu --noconfirm --noprogressbar --color=never", managers[i]);

    if (run_command(command, log_fp))
    {
      update_success = true;
      break;
    }
    fprintf(log_fp, "%s update failed. Check the log for details.\n", managers[i]);
  }

  fprintf(log_fp, update_success ? "System update completed successfully.\n" : "Update failed. No known package manager found or all updates failed.\n");

  fclose(log_fp);
  remove(LOCK_FILE);

  return update_success ? EXIT_SUCCESS : EXIT_FAILURE;
}