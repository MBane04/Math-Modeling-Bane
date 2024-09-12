//nvcc HW6AsteriodsLocalDampingBroken.cu -o bounce -lglut -lm -lGLU -lGL																													
//To stop hit "control c" in the window you launched it from.
#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>
#include <GL/glut.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <cuda.h>
#include <curand.h>
#include <curand_kernel.h>

#define NUMBER_OF_BALLS 20
#define PI 3.14159
using namespace std;

float TotalRunTime;
float RunTime;
float Dt;
float4 Position[NUMBER_OF_BALLS], Velocity[NUMBER_OF_BALLS], Force[NUMBER_OF_BALLS], Color[NUMBER_OF_BALLS];
float SphereMass;
float SphereDiameter;
float BoxSideLength;
float MaxVelocity;
int Trace;
int Pause;
int PrintRate;
int PrintCount;

// Units and universal constants
float MassUnitConverter;
float LengthUnitConverter;
float TimeUnitConverter;
float GavityConstant;

// Window globals
static int Window;
int XWindowSize;
int YWindowSize;
double Near;
double Far;
double EyeX;
double EyeY;
double EyeZ;
double CenterX;
double CenterY;
double CenterZ;
double UpX;
double UpY;
double UpZ;

// Prototyping functions
void Display();
void idle();
void reshape(int, int);
void KeyPressed(unsigned char, int, int);
void setInitailConditions();
void drawPicture();
void getForces();
void updatePositions();
void nBody();
void startMeUp();
void terminalPrint();

void Display()
{
	drawPicture();
}

void idle()
{
	if(Pause == 0) nBody();
}

void reshape(int w, int h)
{
	glViewport(0, 0, (GLsizei) w, (GLsizei) h);
}

void KeyPressed(unsigned char key, int x, int y)
{
	// Turns tracers on and off
	if(key == 't')
	{
		if(Trace == 1) Trace = 0;
		else Trace = 1;
		drawPicture();
		terminalPrint();
	}
	
	if(key == 'p')
	{
		if(Pause == 1) Pause = 0;
		else Pause = 1;
		drawPicture();
		terminalPrint();
	}
	
	// ????????????????????????????????????????????????????????????? SOLVED
	// Add left, right, up, and down functionality to your simulation.
	float dx = 0.05f;
	if(key == 'x')
	{
		glTranslatef(-dx, 0.0, 0.0);
		drawPicture();
		terminalPrint();
	}
	if(key == 'X')
	{
		glTranslatef(dx, 0.0, 0.0);
		drawPicture();
		terminalPrint();
	}

	float dy = 0.05f;
	if(key == 'y')
	{
		glTranslatef(0.0, -dy, 0.0);
		drawPicture();
		terminalPrint();
	}
	if(key == 'Y')
	{
		glTranslatef(0.0, dy, 0.0);
		drawPicture();
		terminalPrint();
	}
	float dz = 0.05f;
	if(key == 'z')
	{
		glTranslatef(0.0, 0.0, -dz);
		drawPicture();
		terminalPrint();
	}
	if(key == 'Z')
	{
		glTranslatef(0.0, 0.0, dz);
		drawPicture();
	}
	
	if(key == 'q')
	{
		glutDestroyWindow(Window);
		printf("\nExiting....\n\nGood Bye\n");
		exit(0);
	}
}

void setInitailConditions()
{
	time_t t;
	float randomNumber;
	//float halfBoxSideLength;
	float sphereRadius;
	float seperation;
	int test;
	
	// Seeding the random number generater.
	srand((unsigned) time(&t));
	
	// The units that we will use to contect us to the outside world are: 
	// kilometers (km)
	// kilograms (kg)
	// hours (hr)
	// If you multiply one of our units by this number it will convert it the outside world units.
	// If you divide an outside world unit by this number it will convert it to our units
	// We are setting the mass unit to be the mass of Ceres.
	// We are settting the length unit to be th diameter of Ceres.
	// We are setting the time unit to be the such that the universal gravity constant is 1.
	MassUnitConverter = 9.383e20; // kg
	LengthUnitConverter = 940.0; // km
	TimeUnitConverter = 3642.0/(60.0*60.0); // hr
	printf("\n MassUnitConverter = %e kilograms", MassUnitConverter);
	printf("\n LengthUnitConverter = %e kilometers", LengthUnitConverter);
	printf("\n TimeUnitConverter = %e hours", TimeUnitConverter);
	
	// If we did everthing right the universal gravity constant should be 1.
	GavityConstant = 1.0;
	printf("\n The gavity constant = %f in our units", GavityConstant);
	
	// All spheres are the same diameter and mass of Ceres so these should be 1..
	SphereDiameter = 1.0;
	SphereMass = 1.0;
	sphereRadius = SphereDiameter/2.0;
	
	// You get to pick this but it is nice to print it out in common units to get a feel for what it is.
	MaxVelocity = 1.0;
	printf("\n Max velocity = %f kilometers/hour or %f miles/hour", MaxVelocity*LengthUnitConverter/TimeUnitConverter, (MaxVelocity*LengthUnitConverter/TimeUnitConverter)*0.621371);
	
	// ?????????????????????????????????????????????????? SOLVED
	// Take the asteroids out of the box so you will not need these. Also remove them from the set of global and local variables 
	//BoxSideLength = 10.0;
	//halfBoxSideLength = BoxSideLength/2.0;
	//printf("\n Box side length = %f kilometers", BoxSideLength*LengthUnitConverter);
	
	// ??????????????????????????????????????????????????
	// You will be initially putting the asteroids inside a big sphere 
	// so you will need a local variable call it maxSphereSize and two other local variables
	// call them angle1 and angle2.

	float randomSphereSize = ((float)rand()/(float)RAND_MAX)*20.0 - 10.0;
	float maxSphereSize = randomSphereSize;
	float angle1, angle2;
	
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		// Settting the balls randomly in a large sphere and not letting them be right on top of each other.
		test = 0;
		while(test == 0)
		{
			// ????????????????????????????????????????????? SOLVED???
			// Change this from a box to a sphere.
			// Get random position.
			angle1 = ((float)rand()/(float)RAND_MAX)*2.0*PI;
			angle2 = ((float)rand()/(float)RAND_MAX)*PI;
  			Position[i].x = maxSphereSize*cos(angle2)*cos(angle1);
			Position[i].z = maxSphereSize*cos(angle2)*sin(angle1);
			Position[i].y = maxSphereSize*sin(angle2);
			
			// Making sure the balls centers are at least a diameter apart.
			// If they are not throw these positions away and try again.
			test = 1;
			for(int j = 0; j < i; j++)
			{
				seperation = sqrt((Position[i].x-Position[j].x)*(Position[i].x-Position[j].x) + (Position[i].y-Position[j].y)*(Position[i].y-Position[j].y) + (Position[i].z-Position[j].z)*(Position[i].z-Position[j].z));
				if(seperation < SphereDiameter)
				{
					test = 0;
					break;
				}
			}
		}
		
		// Setting random velocities between -MaxVelocity and MaxVelocity.
		randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].x = randomNumber;
		randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].y = randomNumber;
		randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].z = randomNumber;
		
		// Color of each asteroid. 
		Color[i].x = 0.35;
		Color[i].y = 0.22;
		Color[i].z = 0.16;
		
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
	}
	
	// Making it run for 10 days.
	// Taking days to hours then to our units.
	TotalRunTime = 10.0*24.0/TimeUnitConverter;
	RunTime = 0.0;
	Dt = 0.001;
	// How many time steps between termenal prints
	PrintRate = 10;
}

void drawPicture()
{
	if(Trace == 0)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glClear(GL_DEPTH_BUFFER_BIT);
	}
	
	float halfSide = BoxSideLength/2.0;
	
	// Drawing balls.
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		glColor3d(Color[i].x, Color[i].y, Color[i].z);
		glPushMatrix();
			glTranslatef(Position[i].x, Position[i].y, Position[i].z);
			glutSolidSphere(SphereDiameter/2.0, 30, 30);
		glPopMatrix();
	}
	
	// ???????????????????????????????????????????????????????? SOLVED
	// If the asteroids are not going to live in a box why draw it. 
	/*
	glLineWidth(3.0);
	//Drawing front of box
	glColor3d(0.0, 1.0, 0.0);
	glBegin(GL_LINE_LOOP);
		glVertex3f(-halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, -halfSide, halfSide);
	glEnd();
	//Drawing back of box
	glColor3d(1.0, 1.0, 1.0);
	glBegin(GL_LINE_LOOP);
		glVertex3f(-halfSide, -halfSide, -halfSide);
		glVertex3f(halfSide, -halfSide, -halfSide);
		glVertex3f(halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, -halfSide, -halfSide);
	glEnd();
	// Finishing off right side
	glBegin(GL_LINES);
		glVertex3f(halfSide, halfSide, halfSide);
		glVertex3f(halfSide, halfSide, -halfSide);
		glVertex3f(halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, -halfSide, -halfSide);
	glEnd();
	// Finishing off left side
	glBegin(GL_LINES);
		glVertex3f(-halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, -halfSide, halfSide);
		glVertex3f(-halfSide, -halfSide, -halfSide);
	glEnd();
	*/
	glutSwapBuffers();
}

void getForces()
{
	// ???????????????????????????????????????????? SOLVED
	// We aren't going to have walls in our new world so you will not need these.
	//float wallStiffnessIn = 10000.0;
	//float wallStiffnessOut = 8000.0;
	//float kWall;
	//float halfSide = BoxSideLength/2.0;
	//float amiuntOut;
	
	// ???????????????????????????????????????????? SOLVED
	// These are a new variable you will use when making the asteroids collide inelastically. 
	float inOut;
	float kSphereReduction;
	float dvx, dvy, dvz;
	
	float kSphere;
	float sphereRadius = SphereDiameter/2.0;
	float d, dx, dy, dz;
	float magnitude;
	
	// Zeroing forces outside of the force loop just to be safe.
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
	}
	
	
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{	
		// ??????????????????????????????????????????????????????????????????? SOLVED
		// Asteroids are free spirits. You can't keep them in a box. 
		// Take them out of the box and let them run free, as they were meant to live!

		/*BE FREE MY ASTEROIDS, BE FREE!

		if((Position[i].x - sphereRadius) < -halfSide)
		{
			amiuntOut = -halfSide - (Position[i].x - sphereRadius);
			if(Velocity[i].x < 0.0) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].x += kWall*amiuntOut;
		}
		else if(halfSide < (Position[i].x + sphereRadius))
		{
			amiuntOut = (Position[i].x + sphereRadius) - halfSide;
			if(0.0 < Velocity[i].x) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].x -= kWall*amiuntOut;
		}
		
		if((Position[i].y - sphereRadius) < -halfSide)
		{
			amiuntOut = -halfSide - (Position[i].y - sphereRadius);
			if(Velocity[i].y < 0.0) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].y += kWall*amiuntOut;
		}
		else if(halfSide < (Position[i].y + sphereRadius))
		{
			amiuntOut = (Position[i].y + sphereRadius) - halfSide;
			if(0.0 < Velocity[i].y) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].y -= kWall*amiuntOut;
		}
		
		if((Position[i].z - sphereRadius) < -halfSide)
		{
			amiuntOut = -halfSide - (Position[i].z - sphereRadius);
			if(Velocity[i].z < 0.0) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].z += kWall*amiuntOut;
		}
		else if(halfSide < (Position[i].z + sphereRadius))
		{
			amiuntOut = (Position[i].z + sphereRadius) - halfSide;
			if(0.0 < Velocity[i].z) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].z -= kWall*amiuntOut;
		}
		*/

		for(int j = 0; j < i; j++)
		{
			dx = Position[j].x - Position[i].x;
			dy = Position[j].y - Position[i].y;
			dz = Position[j].z - Position[i].z;
			d = sqrt(dx*dx + dy*dy + dz*dz);
			
			// ????????????????????????????????????????????????????? SOLVED
			// This causes the asteroids to bounce off of each other elastically.
			// Make this a nonelastic bounce.
			// Make two local variable inOut and kSphereReduction and fix this problem. SOLVED
			// You will also need local variables dvx, dvy, dvz. SOLVED
			// Also check and see if the seperation is less than the radius. SOLVED
			// If it is print out a note to make your repultion stronger and termenate the program.SOLVED

			inOut = dx*dvx + dy*dvy + dz*dvz;
			kSphereReduction = 1.1;
			kSphere = 1000.0;
			dvx = Velocity[j].x - Velocity[i].x;
			dvy = Velocity[j].y - Velocity[i].y;
			dvz = Velocity[j].z - Velocity[i].z;
			

			if(d < SphereDiameter)
			{
				// ????????????????? HALF SOLVED (thanks Dr. Wyatt)
				// I did the radius check for you.
				if(d < sphereRadius)
				{
					printf("\n Spheres %d and %d got to close. Make your sphere repultion stronger\n", i, j);
					exit(0);
				}
				magnitude = kSphere*(SphereDiameter - d);
				float dampingx = kSphereReduction*Velocity[i].x;
				float dampingy = kSphereReduction*Velocity[i].y;	
				float dampingz = kSphereReduction*Velocity[i].z;

				// Doling out the force in the proper perfortions using unit vectors.
				//now to add a kSphereReduction*inOut force to work against the inelastic collision
				Force[i].x -= magnitude*(dx/d) + dampingx;
				Force[i].y -= magnitude*(dy/d) + dampingy;
				Force[i].z -= magnitude*(dz/d) + dampingz;
				// A force on me causes the opposite force on you. 
				Force[j].x += magnitude*(dx/d) - dampingx;
				Force[j].y += magnitude*(dy/d) - dampingy;
				Force[j].z += magnitude*(dz/d) - dampingz;
				printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!THE SPHERES %d and %d COLLIDED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n", i, j);

				//inOut is the most cheeks variable i have ever the misfortune of working with
				//check this out, from the terminal
				//dx = 0.070312
				//dy = -0.714844
				//dz = -0.660156
				//dvx = 0.000000
				//dvy = -0.500000
				//dvz = 0.000000

				//YET FOR WHATEVER GOD FORSAKEN REASON
				//inout = -26616594432.000000

				//AND WHAT MAKES IT WORSE IS ITS ONLY MULTIPLYING, CHECK THE FORMULA, WHAT IS THIS???????????????????
				//I pretty much took it out cause how am I supposed to explain it when the math looks like that
				//DR. WYATT, I AM BEGGING YOU, PLEASE NEVER DO THIS AGAIN


				printf("inout = %f\n", inOut);
				printf("dampingx = %f\n", dampingx);
				printf("dampingy = %f\n", dampingy);
				printf("dampingz = %f\n", dampingz);
			}
			
			// This adds the gravity between asteroids.
			magnitude = GavityConstant*SphereMass*SphereMass/(d*d);
			Force[i].x += magnitude*(dx/d);
			Force[i].y += magnitude*(dy/d);
			Force[i].z += magnitude*(dz/d);
			
			Force[j].x -= magnitude*(dx/d);
			Force[j].y -= magnitude*(dy/d);
			Force[j].z -= magnitude*(dz/d);
			
			// ???????????? Nothing to do. Just a new comic relief.
			// A lady walks into a bar, throws her credit card down, and says, 
			// 'Give me a beer, then half a beer, then a quarter of a beer, then an eighth of a beer, 
			// and just keep them coming.' The bartender pours the lady two beers and says, 
			// 'In this business, you have to know your customer's limits.'
			//
			// Then Chuck Norris's wife walks in, throws her credit card down, and says, 
			// 'Give me a beer, then half a beer, then a third of a beer, then a quarter of a beer, 
			// then a fifth of a beer, and just keep them coming. And when you're done with that, 
			// give me a whiskey chaser.'
			//
			// If you're not laughing, ask Dr. Crawford to explain it in his analysis class. Or ask Kyle.
		}
	}
}

void updatePositions()
{
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		// These are the LeapFrog formulas.
		if(RunTime == 0.0)
		{
			Velocity[i].x += (Force[i].x/SphereMass)*(Dt/2.0);
			Velocity[i].y += (Force[i].y/SphereMass)*(Dt/2.0);
			Velocity[i].z += (Force[i].z/SphereMass)*(Dt/2.0);
		}
		else
		{
			Velocity[i].x += (Force[i].x/SphereMass)*Dt;
			Velocity[i].y += (Force[i].y/SphereMass)*Dt;
			Velocity[i].z += (Force[i].z/SphereMass)*Dt;
			printf("\n Velocity[%d].x = %f", i, Velocity[i].x);
		}

		Position[i].x += Velocity[i].x*Dt;
		Position[i].y += Velocity[i].y*Dt;
		Position[i].z += Velocity[i].z*Dt;
	}
}

void nBody()
{	
	getForces();
	updatePositions();
	drawPicture();
	
	RunTime += Dt;
	PrintCount++;
	
	if(PrintCount == PrintRate)
	{
		terminalPrint();
		PrintCount = 0;
	}
	
	if(TotalRunTime < RunTime)
	{
		glutDestroyWindow(Window);
		printf("\n Later Dude \n");
		exit(0);
	}
}

void startMeUp() 
{	
	// The Rolling Stones
	// Tattoo You: 1981
	Trace = 0;
	Pause = 1;
	PrintCount = 0;
	setInitailConditions();
	printf("\033[0;31m\n\n The simulation is paused. Type p in the simulation window to start it. \n");
	printf("\033[0m");
}

void terminalPrint()
{
	/*
	default  \033[0m
	Black:   \033[0;30m
	Red:     \033[0;31m
	Green:   \033[0;32m
	Yellow:  \033[0;33m
	Blue:    \033[0;34m
	Magenta: \033[0;35m
	Cyan:    \033[0;36m
	White:   \033[0;37m
	printf("\033[0;30mThis text is black.\033[0m\n");
	
	BOLD_ON  "\e[1m"
	BOLD_OFF   "\e[m"
	*/
	
	//system("clear");
	
	// ???????????????????????????????????????? SOLVED
	// let people know how to move left, right, up, and down.
	printf("\n");
	printf("\n X/x: Move left/right");
	printf("\n Y/y: Move up/down");
	printf("\n Z/z: Move in move out");

	
	printf("\033[0m");
	printf("\n t: Trace on/off toggle --> ");
	printf(" Tracing is:");
	if (Trace == 1) 
	{
		printf("\e[1m" " \033[0;32mON\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;31mOFF\n" "\e[m");
	}
	
	printf("\033[0m");
	printf(" p: pause on/off toggle --> ");
	printf(" The simulation is:");
	if (Pause == 1) 
	{
		printf("\e[1m" " \033[0;31mPaused\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;32mRunning\n" "\e[m");
	}
	
	printf(" q: Terminates the simulation");
	
	// Print the time out in hours.
	printf("\n\n Time = %f \033[0;34mhours", RunTime/TimeUnitConverter);
	printf("\033[0m");
	printf("\n");
}


int main(int argc, char** argv)
{
	startMeUp();
	
	XWindowSize = 1000;
	YWindowSize = 1000; 

	// Clip plains
	Near = 0.2;
	Far = 50.0*SphereDiameter;

	//Where your eye is located
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = 15.0*SphereDiameter;

	//Where you are looking
	CenterX = 0.0;
	CenterY = 0.0;
	CenterZ = 0.0;

	//Up vector for viewing
	UpX = 0.0;
	UpY = 1.0;
	UpZ = 0.0;
	
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
	glutInitWindowSize(XWindowSize,YWindowSize);
	glutInitWindowPosition(5,5);
	Window = glutCreateWindow("Particle In A Box");
	
	gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
	glMatrixMode(GL_MODELVIEW);
	
	glClearColor(0.0, 0.0, 0.0, 0.0);
		
	GLfloat light_Position[] = {1.0, 1.0, 1.0, 0.0};
	GLfloat light_ambient[]  = {0.0, 0.0, 0.0, 1.0};
	GLfloat light_diffuse[]  = {1.0, 1.0, 1.0, 1.0};
	GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
	GLfloat mat_specular[]   = {1.0, 1.0, 1.0, 1.0};
	GLfloat mat_shininess[]  = {10.0};
	glShadeModel(GL_SMOOTH);
	glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
	glLightfv(GL_LIGHT0, GL_POSITION, light_Position);
	glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
	glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
	glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_COLOR_MATERIAL);
	glEnable(GL_DEPTH_TEST);
	
	glutDisplayFunc(Display);
	glutReshapeFunc(reshape);
	glutKeyboardFunc(KeyPressed);
	//glutMouseFunc(mymouse);
	glutIdleFunc(idle);
	glutMainLoop();
	
	return 0;
}
