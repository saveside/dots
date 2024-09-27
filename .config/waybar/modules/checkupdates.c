#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 4096
#define MAX_VERSION_LENGTH 20

typedef struct
{
  char pkg_name[BUFFER_SIZE];
  char local_version[MAX_VERSION_LENGTH + 1];
  char new_version[MAX_VERSION_LENGTH + 1];
} UpdateInfo;

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
  char cmd[BUFFER_SIZE];
  snprintf(cmd, sizeof(cmd), "%s/.local/bin/checkupdates", getenv("HOME"));

  int updates_count = 0;
  int updates_capacity = 10;
  UpdateInfo *updates = malloc(updates_capacity * sizeof(UpdateInfo));
  if (!updates)
    return perror("malloc"), EXIT_FAILURE;

  FILE *fp = popen(cmd, "r");
  if (!fp)
    return perror("popen"), free(updates), EXIT_FAILURE;

  char line[BUFFER_SIZE];
  while (fgets(line, sizeof(line), fp))
  {
    if (updates_capacity == updates_count)
    {
      updates_capacity = (updates_capacity * 3) / 2;
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