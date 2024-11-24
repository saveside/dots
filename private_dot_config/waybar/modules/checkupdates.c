#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

#define BUFFER_SIZE 4096
#define MAX_VERSION_LENGTH 20

typedef struct
{
  char pkg_name[BUFFER_SIZE];
  char local_version[MAX_VERSION_LENGTH + 1];
  char new_version[MAX_VERSION_LENGTH + 1];
} UpdateInfo;

void die(const char *msg)
{
  fprintf(stderr, "Error: %s\n", msg);
  exit(EXIT_FAILURE);
}

void check_command(const char *cmd)
{
  if (access(cmd, X_OK) != 0)
    die("Cannot find required binary");
}

void escape_json(const char *input, char *output, size_t size)
{
  static const char *escape_chars = "\"\\\b\f\n\r\t";
  static const char escape_replacements[] = {'\"', '\\', 'b', 'f', 'n', 'r', 't'};

  size_t j = 0;
  for (size_t i = 0; input[i] && j < size - 1; i++)
  {
    char ch = input[i];
    const char *esc_char = strchr(escape_chars, ch);

    if (esc_char)
    {
      if (j + 2 >= size)
        break;
      output[j++] = '\\';
      output[j++] = escape_replacements[esc_char - escape_chars];
    }
    else
      output[j++] = ch;
  }

  output[j] = '\0';
}

int compare_updates(const void *a, const void *b)
{
  return strcmp(((UpdateInfo *)a)->pkg_name, ((UpdateInfo *)b)->pkg_name);
}

int main()
{
  check_command("/usr/bin/fakeroot");

  const char *pms[] = {"/usr/bin/yay", "/usr/bin/paru", "/usr/bin/pacman"};
  const char *pm = NULL;

  for (int i = 0; i < 3; i++)
  {
    if (access(pms[i], X_OK) == 0)
    {
      pm = pms[i];
      break;
    }
  }

  if (!pm)
    die("No supported package manager found");

  char checkup_db[BUFFER_SIZE];
  snprintf(checkup_db, sizeof(checkup_db), "/tmp/checkup-db-%d", getuid());

  if (mkdir(checkup_db, 0755) != 0 && errno != EEXIST)
    die("Failed to create temporary directory");

  char local_path[BUFFER_SIZE];
  snprintf(local_path, sizeof(local_path), "%s/local", checkup_db);

  if (symlink("/var/lib/pacman/local", local_path) != 0 && errno != EEXIST)
    die("Failed to create symlink");

  char cmd[BUFFER_SIZE];
  snprintf(cmd, sizeof(cmd), "fakeroot %s -Sy --dbpath %s --logfile /dev/null &>/dev/null && %s -Qu --dbpath %s 2>/dev/null",
           pm, checkup_db, pm, checkup_db);

  int updates_count = 0;
  int updates_capacity = 16;
  UpdateInfo *updates = malloc(updates_capacity * sizeof(UpdateInfo));
  if (!updates)
    return perror("malloc"), EXIT_FAILURE;

  FILE *fp = popen(cmd, "r");
  if (!fp)
    return perror("popen"), free(updates), EXIT_FAILURE;

  char line[BUFFER_SIZE];
  while (fgets(line, sizeof(line), fp))
  {
    if (updates_count == updates_capacity)
    {
      updates_capacity *= 2;
      UpdateInfo *new_updates = realloc(updates, updates_capacity * sizeof(UpdateInfo));
      if (!new_updates)
        return perror("realloc"), free(updates), EXIT_FAILURE;
      updates = new_updates;
    }

    char local_ver[MAX_VERSION_LENGTH + 1], new_ver[MAX_VERSION_LENGTH + 1];
    char pkg[BUFFER_SIZE];
    int matched = sscanf(line, "%s %s -> %s", pkg, local_ver, new_ver);

    if (matched == 3)
    {
      strncpy(updates[updates_count].pkg_name, pkg, BUFFER_SIZE - 1);
      strncpy(updates[updates_count].local_version, local_ver, MAX_VERSION_LENGTH);
      strncpy(updates[updates_count].new_version, new_ver, MAX_VERSION_LENGTH);
      updates_count++;
    }
  }

  if (pclose(fp) == -1)
    return perror("pclose"), free(updates), EXIT_FAILURE;

  qsort(updates, updates_count, sizeof(UpdateInfo), compare_updates);

  char updates_str[BUFFER_SIZE * 10] = {0};
  for (int i = 0; i < updates_count; i++)
    snprintf(updates_str + strlen(updates_str), sizeof(updates_str) - strlen(updates_str),
             "%-25s %s -> %s\n", updates[i].pkg_name, updates[i].local_version, updates[i].new_version);

  if (updates_count > 0 && updates_str[strlen(updates_str) - 1] == '\n')
    updates_str[strlen(updates_str) - 1] = '\0';

  char pkg_list_escaped[BUFFER_SIZE * 10];
  escape_json(updates_str, pkg_list_escaped, sizeof(pkg_list_escaped));

  printf(updates_count > 0
             ? "{\"text\":\"   %d\",\"tooltip\":\"You have %d pending updates.\\n\\n%s\"}\n"
             : "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}\n",
         updates_count, updates_count, pkg_list_escaped);

  free(updates);
  return 0;
}
