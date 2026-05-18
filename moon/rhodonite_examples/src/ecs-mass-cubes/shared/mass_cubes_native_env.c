/*
 * Optional native overrides for the ecs-mass-cubes sample (entity count).
 */

#include <stdlib.h>

int rhodonite_mass_cubes_entity_count_or_default(int default_count) {
  const char *env = getenv("RHODONITE_MASS_CUBES_ENTITY_COUNT");
  if (env == NULL || env[0] == '\0') {
    return default_count;
  }
  char *end = NULL;
  long value = strtol(env, &end, 10);
  if (end == env || value <= 0L || value > 8000000L) {
    return default_count;
  }
  return (int)value;
}
