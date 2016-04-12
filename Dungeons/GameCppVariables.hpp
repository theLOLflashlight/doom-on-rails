//
//  GameVariables.hpp
//  Dungeons
//
//  Created by Jacob Lim on 2016-04-09.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#ifndef GameCppVariables_hpp
#define GameCppVariables_hpp

#include <stdio.h>
#include <string>
#include "GLHandle.h"
//#include <AVFoundation/AVFoundation.h>
#include "ios_path.h"
#include "glm/glm.hpp"


class GameCppVariables
{
public:
    // Grab the path, make sure to add it to your project!
    //const char* filePath = "footsteps_gravel";
    //std::string sound = ios_path("footsteps_gravel.wav");
    //var audioPlayer = AVAudioPlayer()
    
    //animation for shaking and background color turning brown (due to earthquake)
    float animationProgress = 0.0f;
    
    //Accessible static var - position
    glm::vec3 position = { 0, 0.5, 5 };
    glm::vec3 direction = { 0, 0, 0 };
    glm::vec3 up = { 0, 1, 0 };
    
    glm::vec3 horizontalMovement = { 0, 0, 0 };
};

#endif /* GameVariables_hpp */
