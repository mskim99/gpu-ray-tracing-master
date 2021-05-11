// Copyright 2018 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
// Glue to make data types work.
//
#define vec2 float2
#define vec3 float3
#define vec4 float4

#define FLT_MAX         3.402823466e+38F

// ---------------------------------------------------------------------------------------------- //
// Ray Tracing Structures.
// ---------------------------------------------------------------------------------------------- /

struct Ray {
  vec3 origin;
  vec3 direction;
  vec3 color;
  vec4 accumColor;
  int  bounces;
  int  material;

  vec3 PointAtParameter(float t) {
	  return origin + t * direction;
  }
};

struct HitRecord {
  vec2  uv;
  float t;
  vec3  p;
  vec3  normal;
  vec3  albedo;
  int   material;
};

struct Sphere {
  vec3  center; 
  float radius;
  int   material;
  vec3  albedo;

  bool Hit(Ray r, float tMin, float tMax, out HitRecord rec);
};

struct Plane
{
	vec3 center;
	float scale;
	int material;
	vec3 albedo;

	bool Hit(Ray r, float tMin, float tMax, out HitRecord rec);
 };

 
struct Cube
{
	vec3 center;
	float scale;
	int material;
	vec3 albedo;

	bool Hit(Ray r, float tMin, float tMax, out HitRecord rec);
};

bool Sphere::Hit(Ray r, float tMin, float tMax, out HitRecord rec) {
  rec.t = tMin;
  rec.p = vec3(0,0,0);
  rec.normal = vec3(0,0,0);
  rec.uv = vec2(0,0);
  rec.albedo = albedo;
  rec.material = material;

  vec3 oc = r.origin - center;
  float a = dot(r.direction, r.direction);
  float b = dot(oc, r.direction);
  float c = dot(oc, oc) - radius * radius;
  float discriminant = b*b - a*c;

  if (discriminant <= 0)  {
    return false;
  }
    
  float temp = (-b - sqrt(b*b - a*c)) / a;
  if (temp < tMax && temp > tMin) {
    rec.t = temp;
    rec.p = r.PointAtParameter(rec.t);
    rec.normal = normalize((rec.p - center) / radius);
    return true;
  }

  temp = (-b + sqrt(b*b - a*c)) / a;
  if (temp < tMax && temp > tMin) {
    rec.t = temp;
    rec.p = r.PointAtParameter(rec.t);
    rec.normal = normalize((rec.p - center) / radius);
    return true;
  }

  return false;
}

// Assumption : Plane is not rotated, Camera is in +y
bool Plane::Hit(Ray r, float tMin, float tMax, out HitRecord rec) {
	
  rec.t = tMin;
  rec.p = vec3(0,0,0);
  rec.normal = vec3(0,0,0);
  rec.uv = vec2(0,0);
  rec.albedo = albedo;
  rec.material = material;

  vec3 pn = vec3(0, 1, 0);
  float denom = dot(r.direction, pn);
  if (abs(denom) > 0)
  {
	vec3 oc = r.origin - center;
	float temp = dot(oc, pn) / denom;
	if (temp <= 0) 
	{
		rec.t = temp;
		rec.p = r.PointAtParameter(rec.t);
		rec.normal = pn;
		return true;
	}	
  }

  return false;
}

// Assumption : Same scale for all x, y, z 
bool Cube::Hit(Ray r, float tMin, float tMax, out HitRecord rec) {
	
  rec.t = tMin;
  rec.p = vec3(0,0,0);
  rec.normal = vec3(0,0,0);
  rec.uv = vec2(0,0);
  rec.albedo = albedo;
  rec.material = material;

  // 0 : (1, 0, 0), 1 : (-1, 0, 0)
  // 2 : (0, 1, 0), 3 : (0, -1, 0)
  // 4 : (0, 0, 1), 5 : (0, 0, -1)
  int normalState = 0; 
  bool swapNormal = false;
  float s = 0.5 * scale;

  vec3 minPos = center - vec3(s, s, s);
  vec3 maxPos = center + vec3(s, s, s);

  float tmin = (minPos.x - r.origin.x) / r.direction.x; 
  float tmax = (maxPos.x - r.origin.x) / r.direction.x; 
 
  if (tmin > tmax) // Swap
  {
	float temp = tmin;
	tmin = tmax;
	tmax = temp;

	// normalState = 1;
  }
 
  float tymin = (minPos.y - r.origin.y) / r.direction.y; 
  float tymax = (maxPos.y - r.origin.y) / r.direction.y; 
 
  if (tymin > tymax) // Swap
  {
	float temp = tymin;
	tymin = tymax;
	tymax = temp;

	// swapNormal = true;
  }
 
  if ((tmin > tymax) || (tymin > tmax)) 
      return false; 
 
  if (tymin > tmin)
  {
	tmin = tymin; 

	// if (swapNormal) normalState = 3;
	// else normalState = 2;
  }
       
  if (tymax < tmax) 
      tmax = tymax; 
 
  // swapNormal = false;

  float tzmin = (minPos.z - r.origin.z) / r.direction.z; 
  float tzmax = (maxPos.z - r.origin.z) / r.direction.z; 
 
  if (tzmin > tzmax) // Swap
  {
	float temp = tzmin;
	tzmin = tzmax;
	tzmax = temp;

	// swapNormal = true;
  }
 
  if ((tmin > tzmax) || (tzmin > tmax)) 
      return false; 
 
  if (tzmin > tmin) 
  {
	tmin = tzmin; 

	// if (swapNormal) normalState = 5;
	// else normalState = 4;
  }
      
  if (tzmax < tmax) 
      tmax = tzmax; 
 
  rec.t = tmin;
  rec.p = r.PointAtParameter(rec.t);

  // Calculate Normal  
  vec3 pc = rec.p - center;
  vec3 calNormal = vec3(-1, 0, 0);
   if (pc.x >= - s - 0.0001 && pc.x <= - s + 0.0001) calNormal = vec3(-1, 0, 0);
  else if (pc.x >= s - 0.0001 && pc.x <= s + 0.0001) calNormal = vec3(1, 0, 0);
   if (pc.y >= - s - 0.0001 && pc.y <= - s + 0.0001) calNormal = vec3(0, -1, 0);
  else if (pc.y >= s - 0.0001 && pc.y <= s + 0.0001) calNormal = vec3(0, 1, 0);
   if (pc.z >= - s - 0.0001 && pc.z <= - s + 0.0001) calNormal = vec3(0, 0, -1);
  else if (pc.z >= s - 0.0001 && pc.z <= s + 0.0001) calNormal = vec3(0, 0, 1);  
  rec.normal = calNormal;

  /*
  vec3 calNormal = vec3(1, 0, 0);
  if (normalState == 1) calNormal = vec3(-1, 0, 0);
  else if (normalState == 2) calNormal = vec3(0, 1, 0);
  else if (normalState == 3) calNormal = vec3(0, -1, 0);
  else if (normalState == 4) calNormal = vec3(0, 0, 1);
  else if (normalState == 5) calNormal = vec3(0, 0, -1);
  rec.normal = calNormal;
  */
  return true; 
}
