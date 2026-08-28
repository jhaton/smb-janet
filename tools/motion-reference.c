#include "smbcore/ctx.h"

#include <stdint.h>
#include <stdio.h>
#include <string.h>

static void horizontal_vectors(struct SMB_state *state) {
  static const u8 pages[] = {0x00, 0x01, 0xff};
  static const u8 positions[] = {0x00, 0x01, 0x7f, 0xfe, 0xff};
  static const u8 fractions[] = {0x00, 0x01, 0x7f, 0x80, 0xff};
  static const u8 speeds[] = {0x00, 0x01, 0x7f, 0x80, 0xff};

  for (size_t page_index = 0; page_index < sizeof(pages); page_index++) {
    for (size_t position_index = 0; position_index < sizeof(positions); position_index++) {
      for (size_t fraction_index = 0; fraction_index < sizeof(fractions); fraction_index++) {
        for (size_t speed_index = 0; speed_index < sizeof(speeds); speed_index++) {
          memset(state->rammem, 0, sizeof(state->rammem));
          SprObject_PageLoc[0] = pages[page_index];
          SprObject_X_Position[0] = positions[position_index];
          SprObject_X_MoveForce[0] = fractions[fraction_index];
          SprObject_X_Speed[0] = speeds[speed_index];

          const u8 delta = MoveObjectHorizontally(0);
          printf("H\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\n",
                 pages[page_index], positions[position_index],
                 fractions[fraction_index], speeds[speed_index],
                 SprObject_PageLoc[0], SprObject_X_Position[0],
                 SprObject_X_MoveForce[0], delta);
        }
      }
    }
  }
}

struct gravity_parameters {
  u8 acceleration;
  u8 upward_acceleration;
  u8 maximum_speed;
};

static void gravity_vectors(struct SMB_state *state) {
  static const u8 highs[] = {0x00, 0x01, 0xff};
  static const u8 positions[] = {0x00, 0x7f, 0xff};
  static const u8 fractions[] = {0x00, 0x7f, 0x80, 0xff};
  static const u8 speeds[] = {0x00, 0x01, 0x04, 0x7f, 0x80, 0xfb, 0xff};
  static const u8 forces[] = {0x00, 0x7f, 0x80, 0xff};
  static const struct gravity_parameters parameters[] = {
    {0x04, 0x00, 0x04},
    {0x20, 0x00, 0x04},
    {0x03, 0x06, 0x02},
    {0x05, 0x0a, 0x03},
    {0xff, 0xff, 0x7f},
  };

  for (size_t high_index = 0; high_index < sizeof(highs); high_index++) {
    for (size_t position_index = 0; position_index < sizeof(positions); position_index++) {
      for (size_t fraction_index = 0; fraction_index < sizeof(fractions); fraction_index++) {
        for (size_t speed_index = 0; speed_index < sizeof(speeds); speed_index++) {
          for (size_t force_index = 0; force_index < sizeof(forces); force_index++) {
            for (u8 upward = 0; upward <= 1; upward++) {
              for (size_t parameter_index = 0;
                   parameter_index < sizeof(parameters) / sizeof(parameters[0]);
                   parameter_index++) {
                const struct gravity_parameters parameter = parameters[parameter_index];
                memset(state->rammem, 0, sizeof(state->rammem));
                SprObject_Y_HighPos[0] = highs[high_index];
                SprObject_Y_Position[0] = positions[position_index];
                SprObject_YMF_Dummy[0] = fractions[fraction_index];
                SprObject_Y_Speed[0] = speeds[speed_index];
                SprObject_Y_MoveForce[0] = forces[force_index];

                ImposeGravity(upward, 0, parameter.acceleration,
                              parameter.upward_acceleration,
                              parameter.maximum_speed);
                printf("G\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u"
                       "\t%u\t%u\t%u\t%u\t%u\n",
                       upward, highs[high_index], positions[position_index],
                       fractions[fraction_index], speeds[speed_index],
                       forces[force_index], parameter.acceleration,
                       parameter.upward_acceleration, parameter.maximum_speed,
                       SprObject_Y_HighPos[0], SprObject_Y_Position[0],
                       SprObject_YMF_Dummy[0], SprObject_Y_Speed[0],
                       SprObject_Y_MoveForce[0]);
              }
            }
          }
        }
      }
    }
  }
}

static struct SMB_state state;

int main(void) {
  SMB_STATE = &state;
  horizontal_vectors(&state);
  gravity_vectors(&state);
  return 0;
}
